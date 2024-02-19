class PiecesJustificativesService
  def initialize(user_profile:)
    @user_profile = user_profile
  end

  def liste_documents(dossiers)
    bill_ids = []

    docs = dossiers.in_batches.flat_map do |batch|
      pjs = pjs_for_champs(batch) +
        pjs_for_commentaires(batch) +
        pjs_for_dossier(batch) +
        pjs_for_avis(batch)

      if liste_documents_allows?(:with_bills)
        # some bills are shared among operations
        # so first, all the bill_ids are fetched
        operation_logs, some_bill_ids = operation_logs_and_signature_ids(batch)

        pjs += operation_logs
        bill_ids += some_bill_ids
      end

      pjs
    end

    if liste_documents_allows?(:with_bills)
      # then the bills are retrieved without duplication
      docs += signatures(bill_ids.uniq)
    end

    docs
  end

  def generate_dossiers_export(dossiers)
    return [] if dossiers.empty?

    pdfs = []

    procedure = dossiers.first.procedure
    dossiers = dossiers.includes(:individual, :traitement, :etablissement, user: :france_connect_information, avis: :expert, commentaires: [:instructeur, :expert])
    dossiers = DossierPreloader.new(dossiers).in_batches
    dossiers.each do |dossier|
      dossier.association(:procedure).target = procedure

      pdf = ApplicationController
        .render(template: 'dossiers/show', formats: [:pdf],
                assigns: {
                  acls: acl_for_dossier_export,
                  dossier: dossier
                })

      a = ActiveStorage::FakeAttachment.new(
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

  def acl_for_dossier_export
    case @user_profile
    when Expert
      {
        include_infos_administration: true,
        include_avis_for_expert: true,
        only_for_expert: @user_profile
      }
    when Instructeur, Administrateur
      {
        include_infos_administration: true,
        include_avis_for_expert: true,
        only_for_export: false
      }
    when User
      {
        include_infos_administration: false,
        include_avis_for_expert: false, # should be true, expert can use the messagerie, why not provide avis ?
        only_for_expert: false
      }
    else
      raise 'not supported'
    end
  end

  private

  def liste_documents_allows?(scope)
    case @user_profile
    when Expert
      {
        with_bills: false,
        with_champs_private: false,
        with_avis_piece_justificative: false
      }
    when Instructeur
      {
        with_bills: false,
        with_champs_private: true,
        with_avis_piece_justificative: true
      }
    when Administrateur
      {
        with_bills: true,
        with_champs_private: true,
        with_avis_piece_justificative: true
      }
    else
      raise 'not supported'
    end.fetch(scope)
  end

  def pjs_for_champs(dossiers)
    champs = Champ
      .joins(:piece_justificative_file_attachments)
      .where(type: "Champs::PieceJustificativeChamp", dossier: dossiers)

    if !liste_documents_allows?(:with_champs_private)
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

  def pjs_for_commentaires(dossiers)
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

  def pjs_for_dossier(dossiers)
    motivations(dossiers) +
      attestations(dossiers) +
      etablissements(dossiers)
  end

  def etablissements(dossiers)
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

  def motivations(dossiers)
    ActiveStorage::Attachment
      .includes(:blob)
      .where(record_type: "Dossier", name: "justificatif_motivation", record_id: dossiers)
      .filter { |a| safe_attachment(a) }
      .map do |a|
        dossier_id = a.record_id
        ActiveStorage::DownloadableFile.pj_and_path(dossier_id, a)
      end
  end

  def attestations(dossiers)
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

  def pjs_for_avis(dossiers)
    avis_ids_dossier_id_query = Avis.joins(:dossier).where(dossier: dossiers)
    avis_ids_dossier_id_query = avis_ids_dossier_id_query.where(confidentiel: false) if !liste_documents_allows?(:with_avis_piece_justificative)
    avis_ids_dossier_id = avis_ids_dossier_id_query.pluck(:id, :dossier_id).to_h

    ActiveStorage::Attachment
      .includes(:blob)
      .where(record_type: "Avis", record_id: avis_ids_dossier_id.keys)
      .filter { |a| safe_attachment(a) }
      .map do |a|
        dossier_id = avis_ids_dossier_id[a.record_id]
        ActiveStorage::DownloadableFile.pj_and_path(dossier_id, a)
      end
  end

  def operation_logs_and_signature_ids(dossiers)
    dol_id_dossier_id_bill_id = DossierOperationLog
      .where(dossier: dossiers, data: nil)
      .pluck(:bill_signature_id, :id, :dossier_id)
    dol_id_data_bill_id = DossierOperationLog
      .where(dossier: dossiers)
      .with_data
      .pluck(:bill_signature_id, :id, :dossier_id, :data, :digest, :created_at)

    dol_id_dossier_id = dol_id_dossier_id_bill_id
      .map { |_, dol_id, dossier_id| [dol_id, dossier_id] }
      .to_h

    bill_ids = (dol_id_dossier_id_bill_id + dol_id_data_bill_id)
      .map(&:first)
      .uniq
      .compact

    serialized_dols = ActiveStorage::Attachment
      .includes(:blob)
      .where(record_type: "DossierOperationLog", record_id: dol_id_dossier_id.keys)
      .map do |a|
        dossier_id = dol_id_dossier_id[a.record_id]
        ActiveStorage::DownloadableFile.pj_and_path(dossier_id, a)
      end
    serialized_dols += dol_id_data_bill_id.map do |_, id, dossier_id, data, digest, created_at|
      a = ActiveStorage::FakeAttachment.new(
        file: StringIO.new(data.to_json),
        filename: "operation-#{digest}.json",
        name: 'serialized',
        id: id,
        created_at: created_at,
        record_type: 'DossierOperationLog'
      )
      ActiveStorage::DownloadableFile.pj_and_path(dossier_id, a)
    end

    [serialized_dols, bill_ids]
  end

  def signatures(bill_ids)
    ActiveStorage::Attachment
      .includes(:blob)
      .where(record_type: "BillSignature", record_id: bill_ids)
      .map { |bill| ActiveStorage::DownloadableFile.bill_and_path(bill) }
  end

  def safe_attachment(attachment)
    attachment
      .blob
      .virus_scan_result == ActiveStorage::VirusScanner::SAFE
  end
end
