# frozen_string_literal: true

module MailerMonitoringConcern
  extend ActiveSupport::Concern

  included do
    # Don’t retry to send a message if the server rejects the recipient address
    rescue_from Net::SMTPSyntaxError do |_exception|
      message.perform_deliveries = false
    end

    rescue_from Net::SMTPServerBusy do |exception|
      if /unexpected recipients/.match?(exception.message)
        message.perform_deliveries = false
      end
    end

    def log_delivery_error(exception)
      EmailEvent.create_from_message!(message, status: "dispatch_error")
    end
  end
end
