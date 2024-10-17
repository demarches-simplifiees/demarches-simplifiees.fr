# frozen_string_literal: true

class TypesDeChamp::DropDownListTypeDeChamp < TypesDeChamp::TypeDeChampBase
  def champ_value_for_logic(champ)
    champ.selected
  end
end
