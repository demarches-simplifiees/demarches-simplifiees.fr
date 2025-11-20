# frozen_string_literal: true

class Procedure::Card::AiComponent < ApplicationComponent
  attr_reader :procedure

  def initialize(procedure:)
    @procedure = procedure
  end

  def rule
    last_llm_rule_suggestion&.rule || 'improve_label'
  end

  def render?
    procedure.feature_enabled?(:llm_nightly_improve_procedure)
  end

  private

  def last_llm_rule_suggestion
    @last_suggestion ||= procedure.draft_revision.llm_rule_suggestions.last_for_procedure_revision.first
  end
end
