# frozen_string_literal: true

class LLM::GenerateImproveLabelJob < ApplicationJob
  queue_as :default

  def perform(suggestion)
    suggestion.update!(state: :running)
    # TODO: integrate LLM::LabelImprover service (generate + verify + persist items)
    # For now, mark as completed to avoid re-processing.
    suggestion.update!(state: :completed)
  rescue => e
    suggestion&.update!(state: :failed, error: e.message)
  end
end
