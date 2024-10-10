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
    'default'
  end
end
