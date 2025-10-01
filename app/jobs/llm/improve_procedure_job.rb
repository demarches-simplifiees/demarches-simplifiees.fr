# frozen_string_literal: true

require 'digest'

module LLM
  class ImproveProcedureJob < ApplicationJob
    queue_as :default

    def perform(procedure)
      return unless Flipper.enabled?(:llm_nightly_improve_procedure, procedure)

      procedure_revision = procedure.draft_revision
      return unless procedure_revision

      schema_hash = Digest::SHA256.hexdigest(procedure_revision.schema_to_llm.to_json)

      available_rules.each do |rule|
        suggestion = LLMRuleSuggestion.find_or_initialize_by(procedure_revision:, schema_hash:, rule:)

        next if suggestion.persisted? && !suggestion.failed?
        suggestion.state = :queued
        suggestion.save!
        LLM::GenerateRuleSuggestionJob.perform_later(suggestion)
      end
    end

    private

    def available_rules
      [
        LLM::LabelImprover::TOOL_NAME,
        LLM::StructureImprover::TOOL_NAME
      ]
    end
  end
end
