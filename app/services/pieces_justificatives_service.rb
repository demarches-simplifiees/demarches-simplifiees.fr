class PiecesJustificativesService
  def self.liste_documents(dossier)
    pjs_champs = pjs_for_champs(dossier)
    pjs_commentaires = pjs_for_commentaires(dossier)
    pjs_dossier = pjs_for_dossier(dossier)

    (pjs_champs + pjs_commentaires + pjs_dossier)
      .filter(&:attached?)
  end

  def self.liste_pieces_justificatives(dossier)
    pjs_champs = pjs_for_champs(dossier)
    pjs_commentaires = pjs_for_commentaires(dossier)

    (pjs_champs + pjs_commentaires)
      .filter(&:attached?)
  end

  def self.pieces_justificatives_total_size(dossier)
    liste_pieces_justificatives(dossier)
      .sum(&:byte_size)
  end

  def self.serialize_types_de_champ_as_type_pj(revision)
    tdcs = revision.types_de_champ.filter { |type_champ| type_champ.old_pj.present? }
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

  class FakeAttachment < Hashie::Dash
    property :filename
    property :name
    property :file
    property :id
    property :created_at

    def download
      file
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
  end

  def self.generate_dossier_export(dossier)
    pdf = ApplicationController
      .render(template: 'dossiers/show', formats: [:pdf],
              assigns: {
                include_infos_administration: true,
                dossier: dossier
              })

    FakeAttachment.new(
      file: StringIO.new(pdf),
      filename: "export-#{dossier.id}.pdf",
      name: 'pdf_export_for_instructeur',
      id: dossier.id,
      created_at: dossier.updated_at
    )
  end

  private

  def self.pjs_for_champs(dossier)
    allowed_champs = dossier.champs + dossier.champs_private

    allowed_child_champs = allowed_champs
      .filter { |c| c.type_champ == TypeDeChamp.type_champs.fetch(:repetition) }
      .flat_map(&:champs)

    (allowed_champs + allowed_child_champs)
      .filter { |c| c.type_champ == TypeDeChamp.type_champs.fetch(:piece_justificative) }
      .map(&:piece_justificative_file)
  end

  def self.pjs_for_commentaires(dossier)
    dossier
      .commentaires
      .map(&:piece_jointe)
  end

  def self.pjs_for_dossier(dossier)
    bill_signatures = dossier.dossier_operation_logs.filter_map(&:bill_signature).uniq

    [
      dossier.justificatif_motivation,
      dossier.attestation&.pdf,
      dossier.etablissement&.entreprise_attestation_sociale,
      dossier.etablissement&.entreprise_attestation_fiscale,
      dossier.dossier_operation_logs.map(&:serialized),
      bill_signatures.map(&:serialized),
      bill_signatures.map(&:signature)
    ].flatten.compact
  end
end
