class TypesDeChampEditor::ContextualHelpComponent < ApplicationComponent
  def initialize(type_de_champ:)
    @type_de_champ = type_de_champ
  end

  attr_reader :type_de_champ

  def render?
    @type_de_champ.contextual_help
  end
end
