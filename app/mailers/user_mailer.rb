class UserMailer < ApplicationMailer
  layout 'mailers/layout'

  def new_account_warning(user)
    @user = user
    mail(to: user.email, subject: "Création de compte")
  end
end
