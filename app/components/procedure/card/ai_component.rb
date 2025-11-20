# frozen_string_literal: true

class Procedure::Card::AiComponent < ApplicationComponent
  attr_reader :procedure

  def initialize(procedure:)
    @procedure = procedure
  end

  def rule
    last_llm_rule_suggestion&.rule || 'improve_label'
  end

  private

  def last_llm_rule_suggestion
    @last_suggestion ||= begin
      procedure.draft_revision
        .llm_rule_suggestions
        .order(Arel.sql("
          array_position(ARRAY['improve_label'], llm_rule_suggestions.rule) NULLS LAST,
          CASE WHEN llm_rule_suggestions.state = 'accepted' THEN 1 ELSE 0 END DESC,
          CASE WHEN llm_rule_suggestions.state = 'skipped' THEN 1 ELSE 0 END DESC,
          CASE WHEN llm_rule_suggestions.state = 'completed' THEN 1 ELSE 0 END DESC,
          llm_rule_suggestions.id DESC"))
        .first
    end
  end

  def render?
    procedure.feature_enabled?(:llm_nightly_improve_procedure)
  end
end
