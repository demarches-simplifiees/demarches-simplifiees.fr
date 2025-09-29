# frozen_string_literal: true

class LLM::GenerateImproveLabelJob < ApplicationJob
  queue_as :default

  rescue_from(StandardError) do |exception|
    Sentry.capture_exception(exception, level: :error)
  end

  def perform(suggestion)
    suggestion.update!(state: :running)
    items = service.generate_for(suggestion)
    if items.any?
      LLMRuleSuggestionItem.transaction do
        suggestion.llm_rule_suggestion_items.delete_all
        LLMRuleSuggestionItem.insert_all!(items.map { it.merge(llm_rule_suggestion_id: suggestion.id) })
      end
    end
    suggestion.update!(state: :completed)
  rescue StandardError => e
    suggestion.update!(state: :failed)
    raise e
  end

  def service
    @runner ||= LLM::Runner.new
    @service ||= LLM::LabelImprover.new(runner: @runner)
  end
end
