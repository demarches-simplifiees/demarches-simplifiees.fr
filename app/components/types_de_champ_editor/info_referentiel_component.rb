# frozen_string_literal: true

class TypesDeChampEditor::InfoReferentielComponent < ApplicationComponent
  attr_reader :procedure, :type_de_champ
  delegate :referentiel, to: :type_de_champ
  delegate :ready?, to: :referentiel, allow_nil: true

  def initialize(procedure:, type_de_champ:)
    @procedure = procedure
    @type_de_champ = type_de_champ
  end

  def edit_referentiel_on_draft_or_clone_url
    if new_referentiel_required?
      new_referentiel_url
    else
      edit_existing_referentiel_url
    end
  end

  private

  def new_referentiel_url
    dup_options = referentiel ? { referentiel_id: referentiel.id } : {}
    new_admin_procedure_referentiel_path(procedure, type_de_champ.stable_id, dup_options)
  end

  def edit_existing_referentiel_url
    edit_admin_procedure_referentiel_path(procedure, type_de_champ.stable_id, type_de_champ.referentiel)
  end

  def new_referentiel_required?
    referentiel.nil? || procedure.publiee? || referentiel_used_in_published_procedure?
  end

  def referentiel_used_in_published_procedure?
    Procedure
      .joins(revisions: :types_de_champ)
      .where.not(published_at: nil)
      .exists?(types_de_champ: { referentiel_id: referentiel.id })
  end
end
