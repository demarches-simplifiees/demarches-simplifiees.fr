# frozen_string_literal: true

class LLM::SuggestionFormComponent < ApplicationComponent
  attr_reader :llm_rule_suggestion

  delegate :rule, :procedure_revision, to: :llm_rule_suggestion
  delegate :procedure, to: :procedure_revision
  delegate :step_title, :step_summary, to: :item_component

  def initialize(llm_rule_suggestion:)
    @llm_rule_suggestion = llm_rule_suggestion
  end

  def step_rule
    rule
  end

  def ordered_llm_rule_suggestion_items
    llm_rule_suggestion
      .llm_rule_suggestion_items
      .sort_by { it.payload["position"] }
  end

  def item_component
    case rule
    when 'improve_label'
      LLM::ImproveLabelItemComponent
    when 'improve_structure'
      LLM::ImproveStructureItemComponent
    else
      raise "Unknown LLM rule suggestion view component for rule: #{rule}"
    end
  end

  def prtdcs
    procedure_revision.types_de_champ_public.index_by(&:stable_id)
  end

  def back_link
    helpers.admin_procedure_path(procedure)
  end

  def suggestions_count
    llm_rule_suggestion.llm_rule_suggestion_items.size
  end

  private

  def render?
    llm_rule_suggestion.present?
  end
end
