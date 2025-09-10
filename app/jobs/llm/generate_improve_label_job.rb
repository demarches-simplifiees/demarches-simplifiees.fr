# frozen_string_literal: true

class LLM::GenerateImproveLabelJob < ApplicationJob
  queue_as :default

  def perform(suggestion)
    suggestion.update!(state: :running)
    items = improve_label(suggestion.procedure_revision)
    if items.any?
      llm_rule_suggestion_items = items.map do |value|
        value.merge({
          llm_rule_suggestion_id: suggestion.id
        })
      end
      LLMRuleSuggestionItem.transaction do
        suggestion.llm_rule_suggestion_items.delete_all
        LLMRuleSuggestionItem.insert_all!(llm_rule_suggestion_items)
      end
    end
    suggestion.update!(state: :completed)
  end

  def improve_label(revision)
    service.generate_for(revision)
  end

  def service
    @runner ||= LLM::Runner.new
    @service ||= LLM::LabelImprover.new(runner: @runner)
  end
end
