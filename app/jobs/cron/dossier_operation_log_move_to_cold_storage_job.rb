class Cron::DossierOperationLogMoveToColdStorageJob < Cron::CronJob
  self.schedule_expression = "every day at 1 am"

  def perform
    DossierOperationLog
      .with_data
      .in_batches do |batch|
      DossierOperationLogMoveToColdStorageBatchJob.perform_later(batch.ids)
    end
  end
end
