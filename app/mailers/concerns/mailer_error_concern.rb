module MailerErrorConcern
  extend ActiveSupport::Concern

  included do
    # Don’t retry to send a message if the server rejects the recipient address
    rescue_from Net::SMTPSyntaxError do |_exception|
      message.perform_deliveries = false
    end

    rescue_from Net::SMTPServerBusy do |exception|
      if /unexpected recipients/.match?(exception.message)
        message.perform_deliveries = false
      else
        log_delivery_error(exception)
      end
    end

    rescue_from StandardError, with: :log_delivery_error

    protected

    def log_delivery_error(exception)
      EmailEvent.create_from_message!(message, status: "dispatch_error")
      Sentry.capture_exception(exception, extra: { to: message.to, subject: message.subject })

      # TODO find a way to re attempt the job
    end
  end
end
