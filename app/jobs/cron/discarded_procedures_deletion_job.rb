class Cron::DiscardedProceduresDeletionJob < Cron::CronJob
  self.schedule_expression = "every day at 1 am"

  def perform
    Procedure.purge_discarded
  end
end
