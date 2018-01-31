class InviteMailer < ApplicationMailer
  def invite_user(invite)
    @invite = invite

    subject = "TPS - Participez à l'élaboration d'un dossier"
    reply_to = if invite.user.present? then invite.email_sender end

    mail(to: invite.email, subject: subject, reply_to: reply_to)
  end

  def invite_guest(invite)
    @invite = invite

    subject = "Invitation - #{invite.email_sender} vous invite à consulter un dossier sur la plateforme TPS"

    mail(to: invite.email, subject: subject, reply_to: invite.email_sender)
  end
end
