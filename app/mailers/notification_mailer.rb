class NotificationMailer < ApplicationMailer
  def new_answer dossier
    @user = dossier.user
    @dossier = dossier
    # @url = users_dossier_url id: dossier.id

    mail(from: "tps@apientreprise.fr", to: dossier.user.email,
         subject: "Nouveau commentaire pour votre dossier TPS N°#{dossier.id}")
  end
end
