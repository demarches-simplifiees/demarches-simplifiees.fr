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
        schema = procedure_revision.schema_to_llm.to_json
        schema_hash = Digest::SHA256.hexdigest(schema)

        if !LLMRuleSuggestion.exists?(procedure_revision_id: procedure_revision.id, schema_hash:)
          suggestion = LLMRuleSuggestion.create!(procedure_revision:, schema_hash:, state: :queued, rule: LLM::LabelImprover::TOOL_NAME)

          LLM::GenerateImproveLabelJob.perform_later(suggestion.id)
        end
      end
  end
end
