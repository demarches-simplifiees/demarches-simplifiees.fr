class UpdateAdministrateurUsageStatisticsJob < CronJob
  self.cron_expression = "0 10 * * *"

  def perform
    AdministrateurUsageStatisticsService.new.update_administrateurs
  end
end
