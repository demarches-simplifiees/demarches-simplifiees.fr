# frozen_string_literal: true

class Columns::PieceJustificativeColumn < Column
  private

  def typed_value(champ)
    champ.piece_justificative_file.map { _1.blob.filename.to_s }.join(', ')
  end
end
