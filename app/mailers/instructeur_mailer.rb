# Preview all emails at http://localhost:3000/rails/mailers/instructeur_mailer
class InstructeurMailer < ApplicationMailer
  helper MailerHelper

  layout 'mailers/layout'

  def user_to_instructeur(email)
    @email = email
    subject = "Vous avez été nommé instructeur"

    mail(to: @email, subject: subject)
  end

  def last_week_overview(instructeur)
    email = instructeur.email
    @subject = 'Votre activité hebdomadaire'
    @overview = instructeur.last_week_overview

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

  def send_login_token(instructeur, login_token)
    @instructeur_id = instructeur.id
    @login_token = login_token
    subject = "Connexion sécurisée à #{APPLICATION_NAME}"

    mail(to: instructeur.email, subject: subject)
  end

  def send_notifications(instructeur, data)
    @data = data
    subject = "Vous avez du nouveau sur vos démarches"

    mail(to: instructeur.email, subject: subject)
  end
end
