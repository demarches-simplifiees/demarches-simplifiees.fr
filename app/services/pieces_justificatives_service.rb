class PiecesJustificativesService
  def self.upload!(dossier, user, params)
    tpj_contents = dossier.types_de_piece_justificative
      .map { |tpj| [tpj, params["piece_justificative_#{tpj.id}"]] }
      .select { |_, content| content.present? }

    without_virus, with_virus = tpj_contents
      .partition { |_, content| ClamavService.safe_file?(content.path) }

    errors = with_virus
      .map { |_, content| "#{content.original_filename} : virus détecté" }

    errors + without_virus
      .map { |tpj, content| save_pj(content, dossier, tpj, user) }
      .compact()
  end

  def self.save_pj(content, dossier, tpj, user)
    pj = PieceJustificative.new(content: content,
      dossier: dossier,
      type_de_piece_justificative: tpj,
      user: user)

    pj.save ? nil : "le fichier #{content.original_filename} (#{pj.libelle.truncate(200)}) n'a pas pu être sauvegardé"
  end

  def self.missing_pj_error_messages(dossier)
    mandatory_pjs = dossier.types_de_piece_justificative.select(&:mandatory)
    present_pjs = dossier.pieces_justificatives.map(&:type_de_piece_justificative)
    missing_pjs = mandatory_pjs - present_pjs

    missing_pjs.map { |pj| "La pièce jointe #{pj.libelle.truncate(200)} doit être fournie." }
  end

  def self.types_pj_as_types_de_champ(procedure)
    order_place = procedure.types_de_champ.last&.order_place || 0
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
        mandatory: tpj.mandatory
      )
    end
    if types_de_champ.count > 1
      types_de_champ
    else
      []
    end
  end
end
