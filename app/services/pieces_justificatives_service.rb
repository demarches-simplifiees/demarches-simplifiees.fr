class PiecesJustificativesService
  def self.upload! dossier, user, params
    errors = ''

    dossier.types_de_piece_justificative.each do |type_de_pieces_justificatives|
      unless params["piece_justificative_#{type_de_pieces_justificatives.id}"].nil?

        unless ClamavService.safe_io_data? params["piece_justificative_#{type_de_pieces_justificatives.id}"].path

        end

        piece_justificative = PieceJustificative.new(content: params["piece_justificative_#{type_de_pieces_justificatives.id}"],
                                                     dossier: dossier,
                                                     type_de_piece_justificative: type_de_pieces_justificatives,
                                                     user: user)

        unless piece_justificative.save
          errors << piece_justificative.errors.messages[:content][0]+" (#{piece_justificative.libelle})"+"<br>"
        end


      end
    end
    errors
  end
end