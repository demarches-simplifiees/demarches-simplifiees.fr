class Cron::WeeklyOverviewJob < Cron::CronJob
  self.schedule_expression = "every monday at 04:05"

  def perform
    # Feature flipped to avoid mails in staging due to unprocessed dossier
    return unless Rails.application.config.ds_weekly_overview

    Instructeur.find_each do |instructeur|
      # mailer won't send anything if overview if empty
      InstructeurMailer.last_week_overview(instructeur)&.deliver_later(wait: rand(0..3.hours))
    end
  end
end
