# frozen_string_literal: true

class Cron::TrustedDeviceTokenRenewalJob < Cron::CronJob
  self.schedule_expression = "every day at noon"

  def perform
    TrustedDeviceToken.expiring_in_one_week.find_each do |token|
      begin
        ActiveRecord::Base.transaction do
          token.touch(:renewal_notified_at)
          renewal_token = token.instructeur.create_trusted_device_token
          InstructeurMailer.trusted_device_token_renewal(token.instructeur, renewal_token).deliver_later
        end
      rescue StandardError => e
        Sentry.capture_exception(e)
      end
    end
  end
end
