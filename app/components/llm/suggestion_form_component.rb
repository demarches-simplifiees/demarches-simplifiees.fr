# frozen_string_literal: true

class LLM::SuggestionFormComponent < ApplicationComponent
  attr_reader :llm_rule_suggestion

  def initialize(llm_rule_suggestion:)
    @llm_rule_suggestion = llm_rule_suggestion
  end

  delegate :rule, to: :llm_rule_suggestion

  def step_rule
    rule
  end

  def title = item_component.step_title
  def summary = item_component.step_summary
  def item_component = llm_rule_suggestion.view_component

  def procedure_revision
    llm_rule_suggestion.procedure_revision
  end

  def ordered_llm_rule_suggestion_items
    llm_rule_suggestion
      .llm_rule_suggestion_items
      .sort_by { it.payload[:position] }
  end

  def prtdcs
    procedure_revision.types_de_champ_public.index_by(&:stable_id)
  end

  def procedure
    procedure_revision.procedure
  end

  def back_link
    helpers.admin_procedure_path(procedure)
  end

  private

  def render?
    llm_rule_suggestion.present?
  end
end
