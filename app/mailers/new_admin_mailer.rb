class NewAdminMailer < ApplicationMailer
  def new_admin_email admin, administration
    @admin = admin
    @administration = administration

    mail(to: 'tech@tps.apientreprise.fr',
         subject: "Création d'un compte Admin TPS")
  end
end
