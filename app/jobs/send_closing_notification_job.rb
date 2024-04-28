# frozen_string_literal: true

class SendClosingNotificationJob < ApplicationJob
  def perform(user_ids, content, procedure)
    User.where(id: user_ids).find_each do |user|
      Expired::MailRateLimiter.new().send_with_delay(UserMailer.notify_after_closing(user, content, @procedure))
    end
  end
end
