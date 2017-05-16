class InviteMailer < ApplicationMailer

  def invite_user invite
    vars_mailer invite

    send_mail invite.email, "TPS - Participez à l'élaboration d'un dossier", invite.email_sender unless invite.user.nil?
  end

  def invite_guest invite
    vars_mailer invite

    send_mail invite.email, "Invitation - #{invite.email_sender} vous invite à consulter un dossier sur la plateforme TPS", invite.email_sender
  end

  private

  def vars_mailer invite
    @invite = invite
  end

  def send_mail email, subject, reply_to
    mail(to: email,
         subject: subject,
         reply_to: reply_to)
  end
end
