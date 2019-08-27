class ApplicationMailer < ActionMailer::Base
  helper :application # gives access to all helpers defined within `application_helper`.
  default from: "demarches-simplifiees.fr <#{CONTACT_EMAIL}>"
  layout 'mailer'

  # Attach the procedure logo to the email (if any).
  # Returns the attachment url.
  def attach_logo(procedure)
    return nil if !procedure.logo?

    begin
      if procedure.logo_active_storage.attached?
        logo_filename = procedure.logo_active_storage.filename
        attachments.inline[logo_filename] = procedure.logo_active_storage.download
      else
        logo_filename = procedure.logo.filename
        attachments.inline[logo_filename] = procedure.logo.read
      end
      attachments[logo_filename].url

    rescue StandardError => e
      # A problem occured when reading logo, maybe the logo is missing and we should clean the procedure to remove logo reference ?
      Raven.extra_context(procedure_id: procedure.id)
      Raven.capture_exception(e)
      nil
    end
  end
end
