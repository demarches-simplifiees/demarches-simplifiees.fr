# frozen_string_literal: true

class TypesDeChampEditor::BaseChampComponent < ApplicationComponent
  attr_reader :type_de_champ, :form, :procedure

  def initialize(type_de_champ:, form:, procedure:)
    @type_de_champ = type_de_champ
    @form = form
    @procedure = procedure
  end
end
