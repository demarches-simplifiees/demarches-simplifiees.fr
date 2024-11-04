# frozen_string_literal: true

class Columns::AttachedManyColumn < Columns::ChampColumn
  private

  def typed_value(champ)
    champ.piece_justificative_file.to_a
  end
end
