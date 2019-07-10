# Preview all emails at http://localhost:3000/rails/mailers/user_mailer
class UserMailer < ApplicationMailer
  layout 'mailers/layout'

  def new_account_warning(user)
    @user = user
    @subject = "Demande de création de compte"

    mail(to: user.email, subject: @subject)
  end

  def account_already_taken(user, requested_email)
    @user = user
    @requested_email = requested_email
    @subject = "Changement d’adresse email"

    mail(to: requested_email, subject: @subject)
  end
end
