# frozen_string_literal: true

class TypesDeChampEditor::ChampFormattedSimpleComponent < TypesDeChampEditor::BaseChampComponent
  def render?
    @type_de_champ.formatted_simple?
  end
end
