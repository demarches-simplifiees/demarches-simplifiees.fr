class Cron::DossierOperationLogMoveToColdStorageJob < Cron::CronJob
  self.schedule_expression = "every day at 1 am"

  def perform
    DossierOperationLog
      .with_data
      .find_each(&:move_to_cold_storage!)
  end
end
