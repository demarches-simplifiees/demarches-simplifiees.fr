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
    elsif tunnel_last_llm_rule_suggestion&.finished? && tunnel_last_llm_rule_suggestion.rule == LLM::Rule::SEQUENCE.last
      LLM::Rule::SEQUENCE.last
    else
      LLM::Rule.next_rule(tunnel_last_llm_rule_suggestion.rule) || 'improve_label'
    end
  end

  def tunnel(procedure_revision_id: procedure.draft_revision.id)
    LLM::TunnelFinder.new(procedure_revision_id)
  end

  def any_tunnel_finished?
    @any_tunnel_finished ||= procedure
      .llm_rule_suggestions
      .exists?(rule: LLM::Rule::SEQUENCE.last, state: ['accepted', 'skipped'])
  end

  def tunnel_last_llm_rule_suggestion
    @tunnel_last_llm_rule_suggestion ||= tunnel_last_step_finished(procedure_revision_id: procedure.draft_revision.id)
  end

  def tunnel_first_step(procedure_revision_id:)
    tunnel(procedure_revision_id: procedure_revision_id).first_step
  end

  def tunnel_last_step_finished(procedure_revision_id:)
    tunnel(procedure_revision_id: procedure_revision_id).last_completed_step
  end
end
