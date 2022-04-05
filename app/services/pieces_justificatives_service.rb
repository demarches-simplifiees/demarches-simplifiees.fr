class PiecesJustificativesService
  def self.liste_documents(dossiers, for_expert)
    bill_ids = []

    docs = dossiers.in_batches.flat_map do |batch|
      pjs = pjs_for_champs(batch, for_expert) +
        pjs_for_commentaires(batch) +
        pjs_for_dossier(batch)

      if !for_expert
        # some bills are shared among operations
        # so first, all the bill_ids are fetched
        operation_logs, some_bill_ids = operation_logs_and_signature_ids(batch)

        pjs += operation_logs
        bill_ids += some_bill_ids
      end

      pjs
    end

    if !for_expert
      # then the bills are retrieved without duplication
      docs += signatures(bill_ids.uniq)
    end

    docs
  end

  def self.serialize_types_de_champ_as_type_pj(revision)
    tdcs = revision.types_de_champ_public.filter { |type_champ| type_champ.old_pj.present? }
    tdcs.map.with_index do |type_champ, order_place|
      description = type_champ.description
      if /^(?<original_description>.*?)(?:[\r\n]+)Récupérer le formulaire vierge pour mon dossier : (?<lien_demarche>http.*)$/m =~ description
        description = original_description
      end
      {
        id: type_champ.old_pj[:stable_id],
        libelle: type_champ.libelle,
        description: description,
        order_place: order_place,
        lien_demarche: lien_demarche
      }
    end
  end

  def self.serialize_champs_as_pjs(dossier)
    dossier.champs.filter { |champ| champ.type_de_champ.old_pj }.map do |champ|
      {
        created_at: champ.created_at&.in_time_zone('UTC'),
        type_de_piece_justificative_id: champ.type_de_champ.old_pj[:stable_id],
        content_url: champ.for_api,
        user: champ.dossier.user
      }
    end
  end

  def self.clone_attachments(original, kopy)
    if original.is_a?(TypeDeChamp)
      clone_attachment(original.piece_justificative_template, kopy.piece_justificative_template)
    elsif original.is_a?(Procedure)
      clone_attachment(original.logo, kopy.logo)
      clone_attachment(original.notice, kopy.notice)
      clone_attachment(original.deliberation, kopy.deliberation)
    end
  end

  def self.clone_attachment(original_attachment, copy_attachment)
    if original_attachment.attached?
      original_attachment.open do |tempfile|
        copy_attachment.attach({
          io: File.open(tempfile.path),
          filename: original_attachment.filename,
          content_type: original_attachment.content_type,
          # we don't want to run virus scanner on cloned file
          metadata: { virus_scan_result: ActiveStorage::VirusScanner::SAFE }
        })
      end
    end
  end

  class FakeAttachment < Hashie::Dash
    property :filename
    property :name
    property :file
    property :id
    property :created_at

    def download
      file.read
    end

    def read(*args)
      file.read(*args)
    end

    def close
      file.close
    end

    def attached?
      true
    end

    def record_type
      'Fake'
    end
  end

  def self.generate_dossier_export(dossiers)
    return [] if dossiers.empty?

    pdfs = []

    procedure = dossiers.first.procedure

    dossiers.find_each do |dossier|
      pdf = ApplicationController
        .render(template: 'dossiers/show', formats: [:pdf],
                assigns: {
                  include_infos_administration: true,
                  dossier: dossier,
                  procedure: procedure
                })

      a = FakeAttachment.new(
        file: StringIO.new(pdf),
        filename: "export-#{dossier.id}.pdf",
        name: 'pdf_export_for_instructeur',
        id: dossier.id,
        created_at: dossier.updated_at
      )

      pdfs << ActiveStorage::DownloadableFile.pj_and_path(dossier.id, a)
    end

    pdfs
  end

  private

  def self.pjs_for_champs(dossiers, for_expert = false)
    champs = Champ
      .joins(:piece_justificative_file_attachment)
      .where(type: "Champs::PieceJustificativeChamp", dossier: dossiers)

    if for_expert
      champs = champs.where(private: false)
    end

    champ_id_dossier_id = champs
      .pluck(:id, :dossier_id)
      .to_h

    ActiveStorage::Attachment
      .includes(:blob)
      .where(record_type: "Champ", record_id: champ_id_dossier_id.keys)
      .filter { |a| safe_attachment(a) }
      .map do |a|
        dossier_id = champ_id_dossier_id[a.record_id]
        ActiveStorage::DownloadableFile.pj_and_path(dossier_id, a)
      end
  end

  def self.pjs_for_commentaires(dossiers)
    commentaire_id_dossier_id = Commentaire
      .joins(:piece_jointe_attachment)
      .where(dossier: dossiers)
      .pluck(:id, :dossier_id)
      .to_h

    ActiveStorage::Attachment
      .includes(:blob)
      .where(record_type: "Commentaire", record_id: commentaire_id_dossier_id.keys)
      .filter { |a| safe_attachment(a) }
      .map do |a|
        dossier_id = commentaire_id_dossier_id[a.record_id]
        ActiveStorage::DownloadableFile.pj_and_path(dossier_id, a)
      end
  end

  def self.pjs_for_dossier(dossiers)
    motivations(dossiers) +
      attestations(dossiers) +
      etablissements(dossiers)
  end

  def self.etablissements(dossiers)
    etablissement_id_dossier_id = Etablissement
      .where(dossier: dossiers)
      .pluck(:id, :dossier_id)
      .to_h

    ActiveStorage::Attachment
      .includes(:blob)
      .where(record_type: "Etablissement", record_id: etablissement_id_dossier_id.keys)
      .map do |a|
        dossier_id = etablissement_id_dossier_id[a.record_id]
        ActiveStorage::DownloadableFile.pj_and_path(dossier_id, a)
      end
  end

  def self.motivations(dossiers)
    ActiveStorage::Attachment
      .includes(:blob)
      .where(record_type: "Dossier", name: "justificatif_motivation", record_id: dossiers)
      .filter { |a| safe_attachment(a) }
      .map do |a|
        dossier_id = a.record_id
        ActiveStorage::DownloadableFile.pj_and_path(dossier_id, a)
      end
  end

  def self.attestations(dossiers)
    attestation_id_dossier_id = Attestation
      .joins(:pdf_attachment)
      .where(dossier: dossiers)
      .pluck(:id, :dossier_id)
      .to_h

    ActiveStorage::Attachment
      .includes(:blob)
      .where(record_type: "Attestation", record_id: attestation_id_dossier_id.keys)
      .map do |a|
        dossier_id = attestation_id_dossier_id[a.record_id]
        ActiveStorage::DownloadableFile.pj_and_path(dossier_id, a)
      end
  end

  def self.operation_logs_and_signature_ids(dossiers)
    dol_id_dossier_id_bill_id = DossierOperationLog
      .where(dossier: dossiers)
      .pluck(:id, :dossier_id, :bill_signature_id)

    dol_id_dossier_id = dol_id_dossier_id_bill_id
      .map { |dol_id, dossier_id, _| [dol_id, dossier_id] }
      .to_h

    bill_ids = dol_id_dossier_id_bill_id.map(&:third).uniq.compact

    serialized_dols = ActiveStorage::Attachment
      .includes(:blob)
      .where(record_type: "DossierOperationLog", record_id: dol_id_dossier_id.keys)
      .map do |a|
        dossier_id = dol_id_dossier_id[a.record_id]
        ActiveStorage::DownloadableFile.pj_and_path(dossier_id, a)
      end

    [serialized_dols, bill_ids]
  end

  def self.signatures(bill_ids)
    ActiveStorage::Attachment
      .includes(:blob)
      .where(record_type: "BillSignature", record_id: bill_ids)
      .map { |bill| ActiveStorage::DownloadableFile.bill_and_path(bill) }
  end

  def self.safe_attachment(attachment)
    attachment
      .blob
      .metadata[:virus_scan_result] == ActiveStorage::VirusScanner::SAFE
  end
end
