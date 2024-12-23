# frozen_string_literal: true

class TypesDeChampEditor::InfoReferentielComponent < ApplicationComponent
  attr_reader :type_de_champ

  def initialize(type_de_champ:)
    @type_de_champ = type_de_champ
  end

  def configured?
    false
  end
end
