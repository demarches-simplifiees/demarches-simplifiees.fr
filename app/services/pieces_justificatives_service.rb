class PiecesJustificativesService
  def self.liste_pieces_justificatives(dossier, requesting_account)
    pjs_champs = pjs_for_champs(dossier, requesting_account)
    pjs_commentaires = pjs_for_commentaires(dossier)

    (pjs_champs + pjs_commentaires)
      .filter(&:attached?)
  end

  def self.pieces_justificatives_total_size(dossier, requesting_account)
    liste_pieces_justificatives(dossier, requesting_account)
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

  def self.pjs_for_champs(dossier, requesting_account)
    ChampPolicy::ReadScope.new(requesting_account, Champ).resolve.where(dossier: dossier)
      .filter { |c| c.type_champ == TypeDeChamp.type_champs.fetch(:piece_justificative) }
      .map(&:piece_justificative_file)
  end

  def self.pjs_for_commentaires(dossier)
    dossier
      .commentaires
      .map(&:piece_jointe)
  end
end
