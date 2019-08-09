# Preview all emails at http://localhost:3000/rails/mailers/administrateur_mailer
class AdministrateurMailer < ApplicationMailer
  layout 'mailers/layout'

  def activate_before_expiration(user, reset_password_token)
    @user = user
    @reset_password_token = reset_password_token
    @expiration_date = @user.reset_password_sent_at + Devise.reset_password_within
    @subject = "N'oubliez pas d'activer votre compte administrateur"

    mail(to: user.email,
      subject: @subject,
      reply_to: CONTACT_EMAIL)
  end
end
