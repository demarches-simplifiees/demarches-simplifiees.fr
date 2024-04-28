# frozen_string_literal: true

class TypesDeChampEditor::SelectChampTemplatePositionComponent < ApplicationComponent
  def initialize(block:, coordinates:)
    @block = block
    @coordinates = coordinates
  end

  def block_id
    dom_id(@block, :types_de_champ_editor_select_champ_template)
  end
end
