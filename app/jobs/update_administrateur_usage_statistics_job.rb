class UpdateAdministrateurUsageStatisticsJob < CronJob
  self.schedule_expression = "every day at 10 am"

  def perform
    AdministrateurUsageStatisticsService.new.update_administrateurs
  end
end
