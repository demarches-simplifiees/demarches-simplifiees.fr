# frozen_string_literal: true

class TypesDeChampEditor::ChampFormattedAdvancedComponent < TypesDeChampEditor::BaseChampComponent
  def render?
    @type_de_champ.formatted_advanced?
  end
end
