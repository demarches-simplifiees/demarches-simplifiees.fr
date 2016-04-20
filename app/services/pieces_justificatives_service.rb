class PiecesJustificativesService
  def self.upload! dossier, user, params
    errors = ''

    dossier.types_de_piece_justificative.each do |type_de_pieces_justificatives|
      unless params["piece_justificative_#{type_de_pieces_justificatives.id}"].nil?

        if ClamavService.safe_file? params["piece_justificative_#{type_de_pieces_justificatives.id}"].path
          piece_justificative = PieceJustificative.new(content: params["piece_justificative_#{type_de_pieces_justificatives.id}"],
                                                       dossier: dossier,
                                                       type_de_piece_justificative: type_de_pieces_justificatives,
                                                       user: user)

          unless piece_justificative.save
            errors << piece_justificative.errors.messages[:content][0]+" (#{piece_justificative.libelle})"+"<br>"
          end
        else
          errors << params["piece_justificative_#{type_de_pieces_justificatives.id}"].original_filename+": <b>Virus détecté !!</b>"+"<br>"
        end
      end
    end
    errors
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
end