# frozen_string_literal: true

class TypesDeChampEditor::QuotientFamilialComponent < ApplicationComponent
  def initialize(procedure:, type_de_champ:)
    @procedure = procedure
    @type_de_champ = type_de_champ
  end
end