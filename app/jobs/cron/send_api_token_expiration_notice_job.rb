class Cron::SendAPITokenExpirationNoticeJob < Cron::CronJob
  self.schedule_expression = "every day at midnight"

  def perform
    windows = [
      1.day,
      1.week,
      1.month
    ]

    windows.each do |window|
      APIToken
        .with_expiration_notice_to_send_for(window)
        .find_each do |token|
        APITokenMailer.expiration(token).deliver_later
        token.expiration_notices_sent_at << Time.zone.today
        token.save!
      end
    end
  end
end
