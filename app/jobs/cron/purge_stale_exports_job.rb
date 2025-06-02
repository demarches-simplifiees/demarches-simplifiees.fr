# frozen_string_literal: true

class Cron::PurgeStaleExportsJob < Cron::CronJob
  self.schedule_expression = "every 5 minutes"

  def perform
    Export.stale(Export::MAX_DUREE_CONSERVATION_EXPORT).destroy_all
    Export.stuck(Export::MAX_DUREE_GENERATION).destroy_all
  end
end
