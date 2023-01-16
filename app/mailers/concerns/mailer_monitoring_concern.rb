module MailerMonitoringConcern
  extend ActiveSupport::Concern

  included do
    before_action :add_dolist_header

    # Intercept & log any error, then re-raise so job will retry.
    # NOTE: rescue_from order matters, later matchers are tried first.
    rescue_from StandardError, with: :log_and_raise_delivery_error

    # Don’t retry to send a message if the server rejects the recipient address
    rescue_from Net::SMTPSyntaxError do |_exception|
      message.perform_deliveries = false
    end

    rescue_from Net::SMTPServerBusy do |exception|
      if /unexpected recipients/.match?(exception.message)
        message.perform_deliveries = false
      else
        log_and_raise_delivery_error(exception)
      end
    end

    # mandatory for dolist
    # used for tracking in Dolist UI
    # the delivery_method is yet unknown (:balancer)
    # so we add the dolist header for everyone
    def add_dolist_header
      headers['X-Dolist-Message-Name'] = action_name
    end

    def log_and_raise_delivery_error(exception)
      EmailEvent.create_from_message!(message, status: "dispatch_error")
      Sentry.capture_exception(exception, extra: { to: message.to, subject: message.subject })

      # re-raise another error so job will retry later
      raise MailDeliveryError.new(exception)
    end
  end
end
