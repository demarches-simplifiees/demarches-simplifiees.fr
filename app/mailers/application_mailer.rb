class ApplicationMailer < ActionMailer::Base
  include MailerErrorConcern

  helper :application # gives access to all helpers defined within `application_helper`.
  default from: "#{APPLICATION_NAME} <#{CONTACT_EMAIL}>"
  layout 'mailer'

  before_action :add_dolist_header

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
end
