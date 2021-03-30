class PurgeStaleArchivesJob < CronJob
  self.schedule_expression = "every 5 minutes"

  def perform
    Archive.stale.destroy_all
  end
end
