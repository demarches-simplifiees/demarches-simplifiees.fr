class PiecesJustificativesService
  def self.upload!(dossier, user, params)
    tpj_contents = dossier.types_de_piece_justificative
                          .map { |tpj| [tpj, params["piece_justificative_#{tpj.id}"]] }
                          .select { |_, content| content }

    without_virus, with_virus = tpj_contents
                                .partition { |_, content| ClamavService.safe_file?(content.path) }

    errors = with_virus
             .map { |_, content| content.original_filename + ': <b>Virus détecté !!</b><br>' }

    errors += without_virus
              .map { |tpj, content| save_pj(content, dossier, tpj, user) }

    errors += missing_pj_error_messages(dossier)

    errors.join
  end

  def self.upload_one! dossier, user, params
    if ClamavService.safe_file? params[:piece_justificative][:content].path
      piece_justificative = PieceJustificative.new(content: params[:piece_justificative][:content],
                                                   dossier: dossier,
                                                   type_de_piece_justificative: nil,
                                                   user: user)

      piece_justificative.save
    else
      piece_justificative = PieceJustificative.new
      piece_justificative.errors.add(:content, params[:piece_justificative][:content].original_filename+": <b>Virus détecté !!</b>")
    end

    piece_justificative
  end

  def self.save_pj(content, dossier, tpj, user)
    pj = PieceJustificative.new(content: content,
                                dossier: dossier,
                                type_de_piece_justificative: tpj,
                                user: user)

    pj.save ? '' : "le fichier #{pj.libelle} n'a pas pu être sauvegardé<br>"
  end

  def self.missing_pj_error_messages(dossier)
    mandatory_pjs = dossier.types_de_piece_justificative.select(&:mandatory)
    present_pjs = dossier.pieces_justificatives.map(&:type_de_piece_justificative)
    missing_pjs = mandatory_pjs - present_pjs

    missing_pjs.map { |pj| "La pièce jointe #{pj.libelle} doit être fournie.<br>" }
  end
end
