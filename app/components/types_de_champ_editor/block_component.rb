class TypesDeChampEditor::BlockComponent < ApplicationComponent
  def initialize(block:, coordinates:, upper_coordinates: [])
    @block = block
    @coordinates = coordinates
    @upper_coordinates = upper_coordinates
  end

  private

  def sortable_options
    {
      controller: 'sortable',
      sortable_handle_value: '.handle',
      sortable_group_value: block_id
    }
  end

  def block_id
    dom_id(@block, :types_de_champ_editor_block)
  end
end
