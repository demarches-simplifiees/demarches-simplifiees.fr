class NotificationMailer < ApplicationMailer
  default from: 'tps@apientreprise.fr',
          to:  Proc.new { @user.email }

  def send_notification dossier, mail_template
    vars_mailer(dossier)

    obj  = mail_template.object_for_dossier dossier
    body = mail_template.body_for_dossier dossier

    mail(subject: obj) { |format| format.html { body } }
  end

  def new_answer dossier
    send_mail dossier, "Nouveau message pour votre dossier TPS Nº#{dossier.id}"
  end

  private

  def vars_mailer dossier
    @dossier = dossier
    @user = dossier.user
  end

  def send_mail dossier, subject
    vars_mailer dossier

    mail(subject: subject)
  end
end
