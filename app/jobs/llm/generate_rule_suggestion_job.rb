# frozen_string_literal: true

class LLM::GenerateRuleSuggestionJob < ApplicationJob
  queue_as :default

  rescue_from(StandardError) do |exception|
    Sentry.capture_exception(exception, level: :error)
  end

  def perform(suggestion, action:, user_id: nil)
    suggestion.update!(state: :running)
    items, token_usage = service(suggestion).generate_for(suggestion, action:, user_id:)
    if items.any?
      LLMRuleSuggestionItem.transaction do
        suggestion.llm_rule_suggestion_items.delete_all
        LLMRuleSuggestionItem.insert_all!(items.map { it.merge(llm_rule_suggestion_id: suggestion.id) })
      end
    end
    suggestion.update!(state: :completed, error: nil, token_usage: enhance_token_usage_with_cost(token_usage:))
  rescue StandardError => e
    suggestion.update!(state: :failed, error: e.message)
    raise e
  end

  private

  def enhance_token_usage_with_cost(token_usage:)
    token_usage.merge(
      estimated_cost_eur: LLM::CostCalculator.calculate(
        model: @runner.model,
        prompt_tokens: token_usage[:prompt_tokens],
        completion_tokens: token_usage[:completion_tokens]
      )
    )
  end

  def service(suggestion)
    @runner ||= LLM::Runner.new
    @service ||= begin
      case suggestion.rule
      when 'improve_label'
        return LLM::LabelImprover.new(runner: @runner)
      when 'improve_structure'
        return LLM::StructureImprover.new(runner: @runner)
      else
        raise "Unknown rule: #{suggestion.rule}"
      end
    end
  end
end
