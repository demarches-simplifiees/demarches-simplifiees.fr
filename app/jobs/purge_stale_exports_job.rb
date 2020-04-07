class PurgeStaleExportsJob < CronJob
  self.schedule_expression = "every 5 minutes"

  def perform
    Export.stale.destroy_all
  end
end
