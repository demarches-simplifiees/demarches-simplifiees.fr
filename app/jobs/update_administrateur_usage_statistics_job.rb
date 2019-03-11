class UpdateAdministrateurUsageStatisticsJob < ApplicationJob
  def perform
    AdministrateurUsageStatisticsService.new.update_administrateurs
  end
end
