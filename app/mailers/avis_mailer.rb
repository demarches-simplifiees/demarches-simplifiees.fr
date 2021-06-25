# Preview all emails at http://localhost:3000/rails/mailers/avis_mailer
class AvisMailer < ApplicationMailer
  helper MailerHelper

  layout 'mailers/layout'

  def avis_invitation(avis, reset_password_token)
    if avis.dossier.present?
      @avis = avis
      email = @avis.expert&.email
      @reset_password_token = reset_password_token

      subject = "Donnez votre avis sur le dossier nº #{@avis.dossier.id} (#{@avis.dossier.procedure.libelle})"

      mail(to: email, subject: subject)
    end
  end
end
