class GestionnaireMailer < ApplicationMailer
  layout 'mailers/layout'

  def invite_gestionnaire(gestionnaire, reset_password_token)
    @reset_password_token = reset_password_token
    @gestionnaire = gestionnaire
    subject = "Activez votre compte accompagnateur"

    mail(to: gestionnaire.email,
         subject: subject,
         reply_to: CONTACT_EMAIL)
  end

  def user_to_gestionnaire(email)
    subject = "Vous avez été nommé accompagnateur"

    send_mail(email, nil, subject)
  end

  def last_week_overview(gestionnaire)
    headers['X-mailjet-campaign'] = 'last_week_overview'
    overview = gestionnaire.last_week_overview
    subject = 'Votre activité hebdomadaire'

    send_mail(gestionnaire.email, overview, subject)
  end

  def send_dossier(sender, dossier, recipient)
    @sender = sender
    @dossier = dossier
    subject = "#{sender.email} vous a envoyé le dossier nº #{dossier.id}"

    mail(to: recipient.email, subject: subject)
  end

  private

  def send_mail(email, args, subject)
    @args = args
    @email = email

    mail(to: email, subject: subject)
  end
end
