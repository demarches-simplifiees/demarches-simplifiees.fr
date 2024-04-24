class Procedure::Card::EligibleDossierComponent < ApplicationComponent
  def initialize(procedure:)
    @procedure = procedure
  end

  # TODO: think about condition en_instruction, accepte, refuse, classe_sans_suite
  #       ie: we might extend this behavior to other aasm transition
  #       so `.types_de_champ_public` depend_on the transition
  def ready?
    @procedure.draft_revision
      .conditionable_types_de_champ
      .present?
  end

  def completed?
    @procedure.draft_revision.transitions_rules.present?
  end
end
