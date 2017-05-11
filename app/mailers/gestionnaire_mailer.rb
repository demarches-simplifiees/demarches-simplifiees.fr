class GestionnaireMailer < ApplicationMailer

  def new_gestionnaire email, password
    send_mail email, password, "Vous avez été nommé accompagnateur sur la plateforme TPS"
  end

  def new_assignement email, email_admin
    send_mail email, email_admin, "Vous avez été assigné à un nouvel administrateur sur la plateforme TPS"
  end

  private

  def vars_mailer email, args
    @args = args
    @email = email
  end

  def send_mail email, args, subject
    vars_mailer email, args

    mail(to: email, subject: subject)
  end
end
