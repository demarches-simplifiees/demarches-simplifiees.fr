# Preview all emails at http://localhost:3000/rails/mailers/avis_mailer
class AvisMailer < ApplicationMailer
  helper MailerHelper

  layout 'mailers/layout'

  def avis_invitation(avis, targeted_user_link = nil) # ensure re-entrance if existing AvisMailer.avis_invitation in queue
    if avis.dossier.visible_by_administration?
      targeted_user_link = avis.targeted_user_links
        .find_or_create_by(target_context: 'avis',
                                                  target_model_type: Avis.name,
                                                  target_model_id: avis.id,
                                                  user: avis.expert.user)
      @avis = avis
      email = @avis.expert&.email
      @url = targeted_user_link_url(targeted_user_link)
      subject = "Donnez votre avis sur le dossier nº #{@avis.dossier.id} (#{@avis.dossier.procedure.libelle})"

      mail(to: email, subject: subject)
    end
  end
end
