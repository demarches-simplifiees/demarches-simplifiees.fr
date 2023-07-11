# Preview all emails at http://localhost:3000/rails/mailers/administrateur_mailer
class AdministrateurMailer < ApplicationMailer
  layout 'mailers/layout'

  def activate_before_expiration(user, reset_password_token)
    @user = user
    @reset_password_token = reset_password_token
    @expiration_date = @user.reset_password_sent_at + Devise.reset_password_within
    @subject = "N'oubliez pas d’activer votre compte administrateur"

    mail(to: user.email,
      subject: @subject,
      reply_to: CONTACT_EMAIL)
  end

  def notify_procedure_expires_when_termine_forced(user_email, procedure)
    @procedure = procedure
    @subject = "La suppression automatique des dossiers a été activée sur la démarche #{procedure.libelle}"

    mail(to: user_email,
      subject: @subject,
      reply_to: CONTACT_EMAIL)
  end

  private

  def forced_delivery_for_action?
    action_name == "activate_before_expiration"
  end
end
