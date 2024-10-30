# frozen_string_literal: true

class Columns::TitreIdentiteColumn < Column
  private

  def get_raw_value(champ)
    champ.piece_justificative_file.attached?.to_s
  end
end
