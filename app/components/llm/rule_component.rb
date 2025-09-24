# frozen_string_literal: true

class LLM::RuleComponent < ApplicationComponent
  attr_reader :llm_rule_suggestion, :revision, :prtdcs, :prtdcs_by_stable_id

  def initialize(suggestion:)
    @llm_rule_suggestion = suggestion
    @revision = suggestion.procedure_revision
    @prtdcs = revision.revision_types_de_champ_public
    @prtdcs_by_stable_id = @prtdcs.index_by(&:stable_id)
  end

  def procedure
    @procedure ||= revision.procedure
  end

  def tdc_for(stable_id)
    prtdcs_by_stable_id[stable_id]&.type_de_champ
  end

  def position(stable_id)
    prtdcs_by_stable_id[stable_id]&.position
  end

  def rule
    self.class.key
  end

  def back_link
    simplify_index_admin_procedure_types_de_champ_path(@procedure)
  end
end
