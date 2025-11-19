# frozen_string_literal: true

require 'digest'

module LLM
  class ImproveProcedureJob < ApplicationJob
    queue_as :default

    def perform(procedure, rules)
      return unless Flipper.enabled?(:llm_nightly_improve_procedure, procedure)
      procedure_revision = procedure.draft_revision
      schema_hash = Digest::SHA256.hexdigest(procedure_revision.schema_to_llm.to_json)

      rules.each do |rule|
        suggestion = LLMRuleSuggestion.find_or_initialize_by(procedure_revision:, schema_hash:, rule:)

        next if suggestion.persisted? && !suggestion.failed?
        suggestion.state = :queued
        suggestion.save!
        LLM::GenerateRuleSuggestionJob.perform_later(suggestion)
      end
    end
  end
end
