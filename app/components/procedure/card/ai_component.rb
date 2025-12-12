# frozen_string_literal: true

class Procedure::Card::AiComponent < ApplicationComponent
  attr_reader :procedure

  def initialize(procedure:)
    @procedure = procedure
  end

  def render?
    procedure.feature_enabled?(:llm_nightly_improve_procedure)
  end

  def improved?
    return false if last_llm_rule_suggestion.blank?
    return false if Digest::SHA256.hexdigest(procedure.draft_revision.schema_to_llm.to_json) != last_llm_rule_suggestion.schema_hash

    last_llm_rule_suggestion.finished? && LLMRuleSuggestion.next_rule(last_llm_rule_suggestion.rule).nil?
  end

  private

  def last_llm_rule_suggestion
    @last_llm_rule_suggestion ||= procedure.draft_revision.llm_rule_suggestions.last_for_procedure_revision
  end
end
