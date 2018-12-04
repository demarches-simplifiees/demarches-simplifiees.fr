class ApplicationMailer < ActionMailer::Base
  default from: "demarches-simplifiees.fr <#{CONTACT_EMAIL}>"
  layout 'mailer'

  protected

  def mail_with_reply_hook(dossier, headers = {}, &block)
    @dossier = dossier

    if reply_hook_enabled?(dossier.procedure)
      headers['reply_to'] = mailjet_reply_to_address
      headers['X-MJ-CustomID'] = dossier.id.to_s
      @sent_with_reply_hook = true
    end

    mail(headers, &block)
  end

  private

  def reply_hook_enabled?(procedure)
    allowed_procedures = [
      # TODO: add allowed procedure ids here
    ]

    allowed_procedures.include?(procedure.id) \
      && self.delivery_method == :mailjet \
      && mailjet_reply_to_address.present?
  end

  def mailjet_reply_to_address
    ENV['MAILJET_REPLY_TO']
  end
end
