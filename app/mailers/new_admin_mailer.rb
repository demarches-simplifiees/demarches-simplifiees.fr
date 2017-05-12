class NewAdminMailer < ApplicationMailer
  def new_admin_email admin, password

    @admin = admin
    @password = password

    mail(to: 'tech@apientreprise.fr',
         subject: "Création d'un compte Admin TPS")
  end
end
