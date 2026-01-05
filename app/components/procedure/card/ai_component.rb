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
    any_tunnel_finished?
  end

  def next_rule
    if tunnel_last_llm_rule_suggestion.nil?
      'improve_label'
    elsif tunnel_last_llm_rule_suggestion&.finished? && tunnel_last_llm_rule_suggestion.rule == 'cleaner'
      'cleaner'
    else
      LLMRuleSuggestion.next_rule(tunnel_last_llm_rule_suggestion.rule) || 'improve_label'
    end
  end

  def any_tunnel_finished?
    @any_tunnel_finished ||= procedure
      .llm_rule_suggestions
      .exists?(rule: LLMRuleSuggestion::RULE_SEQUENCE.last, state: ['accepted', 'skipped'])
  end

  def tunnel_last_llm_rule_suggestion
    @tunnel_last_llm_rule_suggestion ||= tunnel_last_step_finished(procedure_revision_id: procedure.draft_revision.id)
  end

  def tunnel_first_step(procedure_revision_id:)
    @tunnel_first_step ||= procedure
      .llm_rule_suggestions
      .where(procedure_revision_id: procedure_revision_id, rule: LLMRuleSuggestion::RULE_SEQUENCE.first)
      .order(created_at: :desc)
      .first
  end

  def tunnel_last_step_finished(procedure_revision_id:)
    base = procedure
      .llm_rule_suggestions
      .where(procedure_revision_id: procedure_revision_id)
      .where(state: ['accepted', 'skipped'])

    if !tunnel_first_step(procedure_revision_id: procedure_revision_id).nil?
      base = base.where(created_at: tunnel_first_step(procedure_revision_id: procedure_revision_id).created_at..)
    end

    @tunnel_last_step_finished ||= base.order(created_at: :desc).first
  end
end
