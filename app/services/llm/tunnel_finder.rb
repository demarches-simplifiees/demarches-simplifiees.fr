# frozen_string_literal: true

class LLM::TunnelFinder
  attr_reader :procedure_revision_id

  def initialize(procedure_revision_id)
    @procedure_revision_id = procedure_revision_id
  end

  def first_step
    @first_step ||= LLMRuleSuggestion
      .where(
        procedure_revision_id: procedure_revision_id,
        rule: LLMRuleSuggestion::RULE_SEQUENCE.first
      )
      .order(created_at: :desc)
      .first
  end

  def final_step
    return nil if first_step.blank?
    @final_step ||= find_completed_step(rule: LLMRuleSuggestion::RULE_SEQUENCE.last)
  end

  def last_completed_step
    @last_completed_step ||= find_completed_step
  end

  private

  def find_completed_step(rule: nil)
    query = LLMRuleSuggestion
      .where(procedure_revision_id: procedure_revision_id)
      .where(state: ['accepted', 'skipped'])

    query = query.where(rule: rule) if rule.present?
    query = query.where(created_at: first_step.created_at..) if first_step.present?

    query.order(created_at: :desc).first
  end
end
