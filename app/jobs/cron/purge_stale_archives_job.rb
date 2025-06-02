# frozen_string_literal: true

class Cron::PurgeStaleArchivesJob < Cron::CronJob
  self.schedule_expression = "every 5 minutes"

  def perform
    Archive.stale(Archive::RETENTION_DURATION).destroy_all
    Archive.stuck(Archive::MAX_DUREE_GENERATION).destroy_all
  end
end
