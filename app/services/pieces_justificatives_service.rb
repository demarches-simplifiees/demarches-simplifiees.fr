class PiecesJustificativesService
  def self.liste_pieces_justificatives(dossier)
    pjs_commentaires = dossier.commentaires
      .map(&:piece_jointe)
      .filter(&:attached?)

    champs_blocs_repetables = dossier.champs
      .filter { |c| c.type_champ == TypeDeChamp.type_champs.fetch(:repetition) }
      .flat_map(&:champs)

    pjs_commentaires + champs_pieces_justificatives_with_attachments(
      champs_blocs_repetables + dossier.champs
    )
  end

  def self.pieces_justificatives_total_size(dossier)
    liste_pieces_justificatives(dossier)
      .sum(&:byte_size)
  end

  def self.serialize_types_de_champ_as_type_pj(procedure)
    tdcs = procedure.types_de_champ.filter { |type_champ| type_champ.old_pj.present? }
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

  private

  def self.champs_pieces_justificatives_with_attachments(champs)
    champs
      .filter { |c| c.type_champ == TypeDeChamp.type_champs.fetch(:piece_justificative) }
      .filter { |pj| pj.piece_justificative_file.attached? }
      .map(&:piece_justificative_file)
  end
end
