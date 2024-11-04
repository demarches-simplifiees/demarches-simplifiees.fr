# frozen_string_literal: true

class Columns::TitreIdentiteColumn < Column
  private

  def typed_value(champ)
    champ.piece_justificative_file.attached?
  end
end
