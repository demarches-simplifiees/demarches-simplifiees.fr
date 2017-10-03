class WeeklyOverviewJob < ApplicationJob
  queue_as :cron

  def perform(*args)
    Rails.logger.info("WeeklyOverviewJob started at #{Time.now}")
    # Feature flipped to avoid mails in staging due to unprocessed dossier
    if Features.weekly_overview
      Gestionnaire.all
        .map { |gestionnaire| [gestionnaire, gestionnaire.last_week_overview] }
        .reject { |_, overview| overview.nil? }
        .each { |gestionnaire, overview| GestionnaireMailer.last_week_overview(gestionnaire, overview).deliver_now }
    end
    Rails.logger.info("WeeklyOverviewJob ended at #{Time.now}")
  end
end
