class AdministrationMailer < ApplicationMailer
  layout 'mailers/layout'

  def new_admin_email(admin, administration)
    @admin = admin
    @administration = administration
    subject = "Création d'un compte Admin demarches-simplifiees.fr"

    mail(to: TECH_EMAIL,
         subject: subject)
  end

  def invite_admin(admin, reset_password_token)
    @reset_password_token = reset_password_token
    @admin = admin
    subject = "demarches-simplifiees.fr - Activez votre compte administrateur"

    mail(to: admin.email,
         subject: subject,
         reply_to: CONTACT_EMAIL)
  end

  def refuse_admin(admin_email)
    subject = "demarches-simplifiees.fr - Votre demande de compte a été refusée"

    mail(to: admin_email,
         subject: subject,
         reply_to: CONTACT_EMAIL)
  end

  def dubious_procedures(procedures_and_type_de_champs)
    @procedures_and_type_de_champs = procedures_and_type_de_champs
    subject = "[RGS] De nouvelles procédures comportent des champs interdits"

    mail(to: EQUIPE_EMAIL,
         subject: subject)
  end
end
