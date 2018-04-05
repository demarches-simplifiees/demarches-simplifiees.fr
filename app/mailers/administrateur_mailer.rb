class AdministrateurMailer < ApplicationMailer
  layout 'mailers/layout'

  def activate_before_expiration(administrateur)
    @administrateur = administrateur
    @expiration_date = administrateur.reset_password_sent_at + Devise.reset_password_within
    mail(to: administrateur.email,
         subject: "demarches-simplifiees.fr - N'oubliez pas d'activer votre compte administrateur",
         reply_to: "contact@demarches-simplifiees.fr")
  end
end
