class UpdateAdministrateurUsageStatisticsJob < ApplicationJob
  queue_as :cron

  def perform
    AdministrateurUsageStatisticsService.new.update_administrateurs
  end
end
