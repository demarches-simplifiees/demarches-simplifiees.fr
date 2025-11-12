# frozen_string_literal: true

class Cron::LLMEnqueueNightlyImproveProcedureJob < Cron::CronJob
  self.schedule_expression = "every day at 02:30"

  def perform(*_args)
    Procedure.publiees
      .order(updated_at: :desc)
      .find_each(batch_size: 200) do |procedure|
        next unless Flipper.enabled?(:llm_nightly_improve_procedure, procedure)

        LLM::GenerateImproveLabelJob.perform_later(procedure.id)
      end
  end
end
