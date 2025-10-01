# frozen_string_literal: true

require 'digest'

module LLM
  class ImproveProcedureJob < ApplicationJob
    queue_as :default

    def perform(procedure)
      return unless Flipper.enabled?(:llm_nightly_improve_procedure, procedure)

      draft_revision = procedure.draft_revision
      schema_hash = Digest::SHA256.hexdigest(draft_revision.schema_to_llm.to_json)
      return if LLMRuleSuggestion.exists?(procedure_revision: draft_revision, schema_hash:)

      available_rules.each do |rule|
        suggestion = LLMRuleSuggestion.create!(procedure_revision: draft_revision, schema_hash:, state: :queued, rule:)
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
