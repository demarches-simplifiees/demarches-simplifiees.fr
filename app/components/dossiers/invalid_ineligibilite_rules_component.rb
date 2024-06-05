class Dossiers::InvalidIneligibiliteRulesComponent < ApplicationComponent
  delegate :can_passer_en_construction?, :ineligibilite_rules_computable?, to: :@dossier

  def initialize(dossier:)
    @dossier = dossier
    @revision = dossier.revision
  end

  def render?
    ineligibilite_rules_computable? && !can_passer_en_construction?
  end

  def error_message
    @dossier.revision.ineligibilite_message
  end
end
