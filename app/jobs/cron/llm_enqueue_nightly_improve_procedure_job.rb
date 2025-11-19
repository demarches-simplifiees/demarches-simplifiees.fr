# frozen_string_literal: true

class Cron::LLMEnqueueNightlyImproveProcedureJob < Cron::CronJob
  self.schedule_expression = "every day at 02:30"

  def perform(*_args)
    Procedure
      .order(updated_at: :desc)
      .find_each(batch_size: 200) do |procedure|
        next unless Flipper.enabled?(:llm_nightly_improve_procedure, procedure)

        LLM::ImproveProcedureJob.perform_later(procedure, [LLMRuleSuggestion.rules.fetch(:improve_label)])
      end
  end
end
