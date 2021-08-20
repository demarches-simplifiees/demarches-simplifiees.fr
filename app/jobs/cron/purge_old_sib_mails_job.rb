class Cron::PurgeOldSibMailsJob < Cron::CronJob
  self.schedule_expression = "every day at midnight"

  def perform
    sib = Sendinblue::API.new
    day_to_delete = (Time.zone.today - 31.days).strftime("%Y-%m-%d")
    sib.delete_events(day_to_delete)
  end
end
