class ApplicationMailer < ActionMailer::Base
  include MailerDolistConcern
  include MailerMonitoringConcern
  include BalancedDeliveryConcern

  helper :application # gives access to all helpers defined within `application_helper`.
  default from: "#{APPLICATION_NAME} <#{CONTACT_EMAIL}>"
  layout 'mailer'

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
end
