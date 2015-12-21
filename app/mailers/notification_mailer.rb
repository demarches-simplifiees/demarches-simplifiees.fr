class NotificationMailer < ApplicationMailer
  def new_answer dossier
    send_mail dossier, "Nouveau commentaire pour votre dossier TPS N°#{dossier.id}"
  end

  def dossier_validated dossier
    send_mail dossier, "Votre dossier TPS N°#{dossier.id} a été validé"
  end

  def dossier_submitted dossier
    send_mail dossier, "Votre dossier TPS N°#{dossier.id} a été déposé"
  end

  private

  def vars_mailer dossier
    @dossier = dossier
    @user = dossier.user
  end

  def send_mail dossier, subject
    vars_mailer dossier

    mail(from: "tps@apientreprise.fr", to: @user.email,
         subject: subject)
  end
end
