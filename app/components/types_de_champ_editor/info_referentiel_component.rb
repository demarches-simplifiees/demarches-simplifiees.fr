# frozen_string_literal: true

class TypesDeChampEditor::InfoReferentielComponent < ApplicationComponent
  attr_reader :procedure, :type_de_champ

  def initialize(procedure:, type_de_champ:)
    @procedure = procedure
    @type_de_champ = type_de_champ
  end

  def new_referentiel_url
    if type_de_champ.referentiel
      edit_admin_procedure_referentiel_path(procedure, type_de_champ.stable_id, type_de_champ.referentiel)
    else
      new_admin_procedure_referentiel_path(procedure, type_de_champ.stable_id)
    end
  end

  def configured?
    false
  end
end
