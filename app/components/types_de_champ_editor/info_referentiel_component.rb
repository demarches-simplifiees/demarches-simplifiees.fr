# frozen_string_literal: true

class TypesDeChampEditor::InfoReferentielComponent < ApplicationComponent
  attr_reader :procedure, :type_de_champ
  delegate :referentiel, to: :type_de_champ

  def initialize(procedure:, type_de_champ:)
    @procedure = procedure
    @type_de_champ = type_de_champ
  end

  def edit_referentiel_on_draft_or_clone_url
    if should_create_new_referentiel?
      dup_existing_referentiel_options = referentiel ? { referentiel_id: referentiel.id } : {}
      new_admin_procedure_referentiel_path(procedure, type_de_champ.stable_id, dup_existing_referentiel_options)
    else
      edit_admin_procedure_referentiel_path(procedure, type_de_champ.stable_id, type_de_champ.referentiel)
    end
  end

  def configured?
    false
  end

  private

  def should_create_new_referentiel?
    return true if referentiel.nil?
    return true if procedure.publiee?

    already_in_use_in_another_procedure?
  end

  def already_in_use_in_another_procedure?
    Procedure.joins(revisions: :types_de_champ)
      .where.not(published_at: nil)
      .exists?(types_de_champ: { referentiel_id: referentiel.id })
  end
end
