# Preview all emails at http://localhost:3000/rails/mailers/avis_mailer
class AvisMailer < ApplicationMailer
  helper MailerHelper

  layout 'mailers/layout'

  def avis_invitation(avis, targeted_user_link)
    if avis.dossier.visible_by_administration?
      @avis = avis
      email = @avis.expert&.email
      @url = targeted_user_link_url(targeted_user_link)
      subject = "Donnez votre avis sur le dossier nº #{@avis.dossier.id} (#{@avis.dossier.procedure.libelle})"

      mail(to: email, subject: subject)
    end
  end
end
