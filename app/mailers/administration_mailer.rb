# Preview all emails at http://localhost:3000/rails/mailers/administration_mailer
class AdministrationMailer < ApplicationMailer
  layout 'mailers/layout'

  def invite_admin(user, reset_password_token, administration_id)
    @reset_password_token = reset_password_token
    @user = user
    @author_name = BizDev.full_name(administration_id)
    subject = "Activez votre compte administrateur"

    mail(to: user.email,
      subject: subject,
      reply_to: CONTACT_EMAIL)
  end

  def refuse_admin(admin_email)
    subject = "Votre demande de compte a été refusée"

    mail(to: admin_email,
      subject: subject,
      reply_to: CONTACT_EMAIL)
  end
end
