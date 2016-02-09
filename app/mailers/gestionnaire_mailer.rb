class GestionnaireMailer < ApplicationMailer

  def new_gestionnaire email, password
    send_mail email, password, "Vous avez été nommé accompagnateur sur la plateforme TPS"
  end

  private

  def vars_mailer email, password
    @password = password
    @email = email
  end

  def send_mail email, password, subject
    vars_mailer email, password

    mail(from: "tps@apientreprise.fr", to: email,
         subject: subject)
  end
end
