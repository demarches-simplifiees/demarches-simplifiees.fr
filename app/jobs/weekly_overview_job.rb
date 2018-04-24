class WeeklyOverviewJob < ApplicationJob
  queue_as :cron

  def perform(*args)
    # Feature flipped to avoid mails in staging due to unprocessed dossier
    if Flipflop.weekly_overview?
      Gestionnaire.all
        .map { |gestionnaire| [gestionnaire, gestionnaire.last_week_overview] }
        .reject { |_, overview| overview.nil? }
        .each { |gestionnaire, _| GestionnaireMailer.last_week_overview(gestionnaire).deliver_later }
    end
  end
end
