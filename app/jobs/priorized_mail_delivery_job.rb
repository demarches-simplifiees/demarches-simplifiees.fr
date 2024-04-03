class PriorizedMailDeliveryJob < ActionMailer::MailDeliveryJob
  discard_on ActiveJob::DeserializationError

  retry_on Net::OpenTimeout, Errno::ECONNRESET, wait: :exponentially_longer, attempts: 10

  def queue_name
    mailer, action_name = @arguments
    if mailer.constantize.critical_email?(action_name)
      super
    else
      custom_queue
    end
  end

  def custom_queue
    ENV.fetch('BULK_EMAIL_QUEUE') { Rails.application.config.action_mailer.deliver_later_queue_name }
  end
end
