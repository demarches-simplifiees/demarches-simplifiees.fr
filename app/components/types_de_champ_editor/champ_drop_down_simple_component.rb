# frozen_string_literal: true

class TypesDeChampEditor::ChampDropDownSimpleComponent < TypesDeChampEditor::BaseChampComponent
  def render?
    !@type_de_champ.drop_down_advanced?
  end
end
