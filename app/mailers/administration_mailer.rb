class AdministrationMailer < ApplicationMailer
  layout 'mailers/layout'

  def new_admin_email(admin, administration)
    @admin = admin
    @administration = administration

    mail(to: 'tech@demarches-simplifiees.fr',
         subject: "Création d'un compte Admin demarches-simplifiees.fr")
  end

  def invite_admin(admin, reset_password_token)
    @reset_password_token = reset_password_token
    @admin = admin
    mail(to: admin.email,
         subject: "demarches-simplifiees.fr - Activez votre compte administrateur",
         reply_to: "contact@demarches-simplifiees.fr")
  end

  def refuse_admin(admin_email)
    mail(to: admin_email,
         subject: "demarches-simplifiees.fr - Votre demande de compte a été refusée",
         reply_to: "contact@demarches-simplifiees.fr")
  end

  def dubious_procedures(procedures_and_type_de_champs)
    @procedures_and_type_de_champs = procedures_and_type_de_champs
    mail(to: 'equipe@demarches-simplifiees.fr',
         subject: "[RGS] De nouvelles procédures comportent des champs interdits")
  end
end
