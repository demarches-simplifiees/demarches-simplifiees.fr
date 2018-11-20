# Preview all emails at http://localhost:3000/rails/mailers/invite_mailer
class InviteMailer < ApplicationMailer
  def invite_user(invite)
    subject = "Participez à l'élaboration d'un dossier"

    if invite.user.present?
      send_mail(invite, subject, invite.email_sender)
    end
  end

  def invite_guest(invite)
    subject = "#{invite.email_sender} vous invite à consulter un dossier"

    send_mail(invite, subject, invite.email_sender)
  end

  private

  def send_mail(invite, subject, reply_to)
    @invite = invite
    email = invite.email

    mail(to: email,
      subject: subject,
      reply_to: reply_to)
  end
end
