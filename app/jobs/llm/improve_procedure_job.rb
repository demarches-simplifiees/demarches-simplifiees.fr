# frozen_string_literal: true

require 'digest'

module LLM
  class ImproveProcedureJob < ApplicationJob
    queue_as :default

    def perform(procedure, rule, action:, user_id: nil)
      return unless Flipper.enabled?(:llm_nightly_improve_procedure, procedure)
      procedure_revision = procedure.draft_revision
      schema_hash = Digest::SHA256.hexdigest(procedure_revision.schema_to_llm.to_json)

      suggestion = LLMRuleSuggestion
        .where(procedure_revision:, schema_hash:, rule:)
        .first

      return if suggestion&.persisted? && !suggestion&.failed?

      suggestion ||= LLMRuleSuggestion.new(procedure_revision:, schema_hash:, rule:)
      suggestion.state = :queued
      suggestion.save!
      LLM::GenerateRuleSuggestionJob.perform_later(suggestion, action:, user_id:)
    end
  end
end
