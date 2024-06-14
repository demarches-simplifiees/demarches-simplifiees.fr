class Procedure::Card::IneligibiliteDossierComponent < ApplicationComponent
  def initialize(procedure:)
    @procedure = procedure
  end

  def ready?
    @procedure.draft_revision
      .conditionable_types_de_champ
      .present? && @procedure.draft_revision.ineligibilite_enabled
  end

  def error?
    !@procedure.draft_revision.validate(:ineligibilite_rules_editor)
  end

  def completed?
    @procedure.draft_revision.ineligibilite_enabled
  end
end
