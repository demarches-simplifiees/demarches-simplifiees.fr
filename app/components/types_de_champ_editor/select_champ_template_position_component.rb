class TypesDeChampEditor::SelectChampTemplatePositionComponent < ApplicationComponent
  def initialize(block:, coordinates:)
    @block = block
    @coordinates = coordinates.includes(:type_de_champ)
  end

  def block_id
    dom_id(@block, :types_de_champ_editor_select_champ_template)
  end
end
