class GestionnaireMailer < ApplicationMailer
  layout 'mailers/layout'

  def invite_gestionnaire(gestionnaire, reset_password_token)
    @reset_password_token = reset_password_token
    @gestionnaire = gestionnaire
    subject = "demarches-simplifiees.fr - Activez votre compte accompagnateur"

    mail(to: gestionnaire.email,
         subject: subject,
         reply_to: "contact@demarches-simplifiees.fr")
  end

  def user_to_gestionnaire(email)
    subject = "Vous avez été nommé accompagnateur sur demarches-simplifiees.fr"

    send_mail(email, nil, subject)
  end

  def last_week_overview(gestionnaire)
    headers['X-mailjet-campaign'] = 'last_week_overview'
    overview = gestionnaire.last_week_overview
    subject = 'Vos activités sur demarches-simplifiees.fr'

    send_mail(gestionnaire.email, overview, subject)
  end

  def send_dossier(sender, dossier, recipient)
    @sender = sender
    @dossier = dossier
    subject = "#{sender.email} vous a envoyé le dossier nº #{dossier.id}"

    mail(to: recipient.email, subject: subject)
  end

  private

  def vars_mailer(email, args)
    @args = args
    @email = email
  end

  def send_mail(email, args, subject)
    vars_mailer email, args

    mail(to: email, subject: subject)
  end
end
