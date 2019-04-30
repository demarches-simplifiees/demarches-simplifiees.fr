# Preview all emails at http://localhost:3000/rails/mailers/gestionnaire_mailer
class GestionnaireMailer < ApplicationMailer
  layout 'mailers/layout'

  def invite_gestionnaire(gestionnaire, reset_password_token)
    @reset_password_token = reset_password_token
    @gestionnaire = gestionnaire
    subject = "Activez votre compte instructeur"

    mail(to: gestionnaire.email,
      subject: subject,
      reply_to: CONTACT_EMAIL)
  end

  def user_to_gestionnaire(email)
    @email = email
    subject = "Vous avez été nommé instructeur"

    mail(to: @email, subject: subject)
  end

  def last_week_overview(gestionnaire)
    email = gestionnaire.email
    @subject = 'Votre activité hebdomadaire'
    @overview = gestionnaire.last_week_overview

    if @overview.present?
      headers['X-mailjet-campaign'] = 'last_week_overview'
      mail(to: email, subject: @subject)
    end
  end

  def send_dossier(sender, dossier, recipient)
    @sender = sender
    @dossier = dossier
    subject = "#{sender.email} vous a envoyé le dossier nº #{dossier.id}"

    mail(to: recipient.email, subject: subject)
  end

  def send_login_token(gestionnaire, login_token)
    @gestionnaire_id = gestionnaire.id
    @login_token = login_token
    subject = "Connexion sécurisée à #{SITE_NAME}"

    mail(to: gestionnaire.email, subject: subject)
  end

  def send_notifications(gestionnaire, data)
    @data = data
    subject = "Vous avez du nouveau sur vos démarches"

    mail(to: gestionnaire.email, subject: subject)
  end
end
