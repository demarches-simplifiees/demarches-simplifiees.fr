# Preview all emails at http://localhost:3000/rails/mailers/user_mailer
class UserMailer < ApplicationMailer
  layout 'mailers/layout'

  def new_account_warning(user)
    @user = user
    @subject = "Demande de création de compte"

    mail(to: user.email, subject: @subject)
  end
end
