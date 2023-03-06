class Cron::WeeklyOverviewJob < Cron::CronJob
  self.schedule_expression = "every monday at 7 am"

  def perform
    # Feature flipped to avoid mails in staging due to unprocessed dossier
    return unless Rails.application.config.ds_weekly_overview

    Instructeur.find_each do |instructeur|
      # NOTE: it's not exactly accurate because rate limit is not shared between jobs processes
      Dolist::API.sleep_until_limit_reset if Dolist::API.near_rate_limit?

      # mailer won't send anything if overview if empty
      InstructeurMailer.last_week_overview(instructeur)&.deliver_later
    end
  end
end
