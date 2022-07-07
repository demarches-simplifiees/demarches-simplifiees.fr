class Cron::PurgeStaleExportsJob < Cron::CronJob
  self.schedule_expression = "every 5 minutes"

  def perform
    Export.stale(Export::MAX_DUREE_CONSERVATION_EXPORT).destroy_all
  end
end
