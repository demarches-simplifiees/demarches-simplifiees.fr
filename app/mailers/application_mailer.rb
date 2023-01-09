class ApplicationMailer < ActionMailer::Base
  helper :application # gives access to all helpers defined within `application_helper`.
  default from: "#{APPLICATION_NAME} <#{CONTACT_EMAIL}>"
  layout 'mailer'

  before_action :add_dolist_header

  # Don’t retry to send a message if the server rejects the recipient address
  rescue_from Net::SMTPSyntaxError do |_exception|
    message.perform_deliveries = false
  end

  rescue_from Net::SMTPServerBusy do |exception|
    if /unexpected recipients/.match?(exception.message)
      message.perform_deliveries = false
    else
      log_smtp_error(exception)
    end
  end

  rescue_from Net::SMTPError, with: :log_smtp_error

  # Attach the procedure logo to the email (if any).
  # Returns the attachment url.
  def attach_logo(procedure)
    if procedure.logo.attached?
      logo_filename = procedure.logo.filename.to_s
      attachments.inline[logo_filename] = procedure.logo.download
      attachments[logo_filename].url
    end

  rescue StandardError => e
    # A problem occured when reading logo, maybe the logo is missing and we should clean the procedure to remove logo reference ?
    Sentry.capture_exception(e, extra: { procedure_id: procedure.id })
    nil
  end

  # mandatory for dolist
  # used for tracking in Dolist UI
  # the delivery_method is yet unknown (:balancer)
  # so we add the dolist header for everyone
  def add_dolist_header
    headers['X-Dolist-Message-Name'] = action_name
  end

  def log_smtp_error(exception)
    if defined?(message) && message.to.present?
      EmailEvent.create_from_message!(message, status: "dispatch_error")
    end

    Sentry.capture_exception(exception, extra: { to: message&.to, subject: message&.subject })

    # TODO find a way to re attempt the job
  end
end
