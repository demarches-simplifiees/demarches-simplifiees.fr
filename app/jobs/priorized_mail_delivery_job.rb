# frozen_string_literal: true

class PriorizedMailDeliveryJob < ActionMailer::MailDeliveryJob
  discard_on ActiveJob::DeserializationError

  def queue_name
    mailer, action_name = @arguments
    if mailer.constantize.critical_email?(action_name)
      super
    else
      custom_queue
    end
  end

  def custom_queue
    ENV.fetch('BULK_EMAIL_QUEUE') { Rails.application.config.action_mailer.deliver_later_queue_name.to_s }
  end
end
