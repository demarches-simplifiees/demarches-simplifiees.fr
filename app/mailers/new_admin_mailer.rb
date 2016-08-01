class NewAdminMailer < ApplicationMailer
  def new_admin_email admin, password

    @admin = admin
    @password = password

    mail(from: "tps@apientreprise.fr", to: 'tech@apientreprise.fr',
         subject: "Création d'un compte Admin TPS")
  end
end
