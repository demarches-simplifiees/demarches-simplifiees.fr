class WelcomeMailer < ApplicationMailer
  def welcome_email user

    @user = user

    mail(from: "tps@apientreprise.fr", to: user.email,
         subject: "Création de votre compte TPS")
  end
end
