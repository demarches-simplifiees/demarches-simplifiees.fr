class WeeklyOverviewJob < CronJob
  self.schedule_expression = "every monday at 7 am"

  def perform(*args)
    # Feature flipped to avoid mails in staging due to unprocessed dossier
    if Rails.application.config.ds_weekly_overview
      Instructeur.all
        .map { |instructeur| [instructeur, instructeur.last_week_overview] }
        .reject { |_, overview| overview.nil? }
        .each { |instructeur, _| InstructeurMailer.last_week_overview(instructeur).deliver_later }
    end
  end
end
