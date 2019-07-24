class PiecesJustificativesService
   def self.types_pj_as_types_de_champ(procedure)
    max_order_place = procedure.types_de_champ.pluck(:order_place).compact.max || -1
    order_place = max_order_place + 1

    types_de_champ = [
      TypeDeChamp.new(
        libelle: "Pièces jointes",
        type_champ: TypeDeChamp.type_champs.fetch(:header_section),
        order_place: order_place
      )
    ]
    types_de_champ += procedure.types_de_piece_justificative.map do |tpj|
      order_place += 1
      description = tpj.description
      if tpj.lien_demarche.present?
        if description.present?
          description += "\n"
        end
        description += "Récupérer le formulaire vierge pour mon dossier : #{tpj.lien_demarche}"
      end
      TypeDeChamp.new(
        libelle: tpj.libelle,
        type_champ: TypeDeChamp.type_champs.fetch(:piece_justificative),
        description: description,
        order_place: order_place,
        mandatory: tpj.mandatory,
        old_pj: {
          stable_id: tpj.id
        }
      )
    end
    if types_de_champ.count > 1
      types_de_champ
    else
      []
    end
  end

  def self.liste_pieces_justificatives(dossier)
    dossier.champs
      .select { |c| c.type_champ == TypeDeChamp.type_champs.fetch(:piece_justificative) }
      .filter { |pj| pj.piece_justificative_file.attached? }
  end

  def self.pieces_justificatives_total_size(dossier)
    liste_pieces_justificatives(dossier)
      .sum { |pj| pj.piece_justificative_file.byte_size }
  end

  def self.serialize_types_de_champ_as_type_pj(procedure)
    tdcs = procedure.types_de_champ.select { |type_champ| type_champ.old_pj.present? }
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
    dossier.champs.select { |champ| champ.type_de_champ.old_pj }.map do |champ|
      {
        created_at: champ.created_at&.in_time_zone('UTC'),
        type_de_piece_justificative_id: champ.type_de_champ.old_pj[:stable_id],
        content_url: champ.for_api,
        user: champ.dossier.user
      }
    end
  end
end
