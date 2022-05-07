class TypesDeChampEditor::BlockComponent < ApplicationComponent
  def initialize(id:, types_de_champ:)
    @id = id
    @types_de_champ = types_de_champ
  end

  attr_reader :id, :types_de_champ
end
