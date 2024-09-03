# frozen_string_literal: true

class Cron::DiscardedProceduresDeletionJob < Cron::CronJob
  self.schedule_expression = "every day at 00:45"

  def perform
    Procedure.purge_discarded
  end
end
