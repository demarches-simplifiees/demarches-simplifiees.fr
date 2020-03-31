class PurgeStaleExportsJob < CronJob
  self.cron_expression = "*/5 * * * *"

  def perform
    Export.stale.destroy_all
  end
end
