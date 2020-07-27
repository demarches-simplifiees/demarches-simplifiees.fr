class ApplicationMailer < ActionMailer::Base
  helper :application # gives access to all helpers defined within `application_helper`.
  default from: "#{APPLICATION_NAME} <#{CONTACT_EMAIL}>"
  layout 'mailer'

  # Don’t retry to send a message if the server rejects the recipient address
  rescue_from Net::SMTPSyntaxError do |_error|
    message.perform_deliveries = false
  end

  rescue_from Net::SMTPServerBusy do |error|
    if error.message =~ /unexpected recipients/
      message.perform_deliveries = false
    end
  end

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
    Raven.extra_context(procedure_id: procedure.id)
    Raven.capture_exception(e)
    nil
  end
end
