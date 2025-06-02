# frozen_string_literal: true

class TypesDeChampEditor::BlockComponent < ApplicationComponent
  def initialize(block:, coordinates:, upper_coordinates: [])
    @block = block
    @coordinates = coordinates
    @upper_coordinates = upper_coordinates
  end

  private

  def block_id
    dom_id(@block, :types_de_champ_editor_block)
  end
end
