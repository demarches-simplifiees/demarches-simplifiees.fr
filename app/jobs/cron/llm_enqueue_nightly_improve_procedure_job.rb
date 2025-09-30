# frozen_string_literal: true

require 'digest'

class Cron::LLMEnqueueNightlyImproveProcedureJob < Cron::CronJob
  self.schedule_expression = "every day at 02:30"

  def perform(*_args)
    Procedure.publiees
      .order(updated_at: :desc)
      .find_each(batch_size: 200) do |procedure|
        next unless Flipper.enabled?(:llm_nightly_improve_procedure, procedure)
        procedure_revision = procedure.published_revision
        schema_hash = schema_hash(procedure_revision)
        next if LLMRuleSuggestion.exists?(procedure_revision:, schema_hash:)

        available_rules.each do |rule|
          suggestion = LLMRuleSuggestion.create!(procedure_revision:, schema_hash:, state: :queued, rule:)
          LLM::GenerateRuleSuggestionJob.perform_later(suggestion)
        end
      end
  end

  def schema_hash(procedure_revision)
    Digest::SHA256.hexdigest(procedure_revision.schema_to_llm.to_json)
  end

  def available_rules
    [
      LLM::LabelImprover::TOOL_NAME,
      LLM::StructureImprover::TOOL_NAME
    ]
  end
end
