class AdministrationMailer < ApplicationMailer
  layout 'mailers/layout'

  def new_admin_email admin, administration
    @admin = admin
    @administration = administration

    mail(to: 'tech@tps.apientreprise.fr',
         subject: "Création d'un compte Admin TPS")
  end

  def invite_admin(admin, reset_password_token)
    @reset_password_token = reset_password_token
    mail(to: admin.email,
         subject: "TPS - Activez votre compte administrateur",
         reply_to: "equipe@tps.apientreprise.fr")
  end

  def dubious_procedures(procedures_and_type_de_champs)
    @procedures_and_type_de_champs = procedures_and_type_de_champs
    mail(to: 'equipe@tps.apientreprise.fr',
         subject: "[RGS] De nouvelles procédures comportent des champs interdits")
  end
end
