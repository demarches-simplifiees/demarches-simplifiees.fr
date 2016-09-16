class NotificationMailer < ApplicationMailer
  def new_answer dossier
    send_mail dossier, "Nouveau commentaire pour votre dossier TPS N°#{dossier.id}"
  end

  def dossier_received dossier
    send_mail dossier, MailTemplate.replace_tags(dossier.procedure.mail_received.object, dossier)
  end

  def dossier_validated dossier
    send_mail dossier, "Votre dossier TPS N°#{dossier.id} a été validé"
  end

  def dossier_submitted dossier
    send_mail dossier, "Votre dossier TPS N°#{dossier.id} a été déposé"
  end

  def dossier_without_continuation dossier
    send_mail dossier, "Votre dossier TPS N°#{dossier.id} a été classé sans suite"
  end

  def dossier_refused dossier
    send_mail dossier, "Votre dossier TPS N°#{dossier.id} a été refusé"
  end

  def dossier_closed dossier
    send_mail dossier, "Votre dossier TPS N°#{dossier.id} a été accepté"
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
