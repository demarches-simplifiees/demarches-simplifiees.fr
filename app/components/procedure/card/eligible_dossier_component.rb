class Procedure::Card::EligibleDossierComponent < ApplicationComponent
  def initialize(procedure:)
    @procedure = procedure
  end

  # TODO: think about condition en_instruction, accepte, refuse, classe_sans_suite
  #       ie: we might extend this behavior to other aasm transition
  #       so `.types_de_champ_public` depend_on the transition
  def ready?
    @procedure.active_revision
      .types_de_champ_public
      .any? { Logic::ChampValue::MANAGED_TYPE_DE_CHAMP.values.include?(_1.type_champ) }
  end

  def completed?
    false
  end
end
