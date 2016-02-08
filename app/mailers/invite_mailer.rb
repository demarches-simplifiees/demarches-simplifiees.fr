class InviteMailer < ApplicationMailer

  def invite_user invite
    vars_mailer invite

    send_mail invite.email, "TPS - Participez à l'élaboration d'un dossier" unless invite.user.nil?
  end

  def invite_guest invite
    vars_mailer invite

    send_mail invite.email, "Invitation - #{invite.email_sender} vous invite à consulter un dossier sur la plateforme TPS"
  end

  private

  def vars_mailer invite
    @invite = invite
  end

  def send_mail email, subject
    mail(from: "tps@apientreprise.fr", to: email,
         subject: subject)
  end
end
