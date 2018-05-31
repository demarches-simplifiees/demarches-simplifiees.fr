class InviteMailer < ApplicationMailer
  def invite_user(invite)
    vars_mailer(invite)

    send_mail(invite.email, "demarches-simplifiees.fr - Participez à l'élaboration d'un dossier", invite.email_sender) if invite.user.present?
  end

  def invite_guest(invite)
    vars_mailer(invite)

    send_mail(invite.email, "Invitation - #{invite.email_sender} vous invite à consulter un dossier sur demarches-simplifiees.fr", invite.email_sender)
  end

  private

  def vars_mailer(invite)
    @invite = invite
  end

  def send_mail(email, subject, reply_to)
    mail(to: email,
         subject: subject,
         reply_to: reply_to)
  end
end
