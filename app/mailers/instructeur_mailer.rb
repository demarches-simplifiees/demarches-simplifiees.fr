# frozen_string_literal: true

# Preview all emails at http://localhost:3000/rails/mailers/instructeur_mailer
class InstructeurMailer < ApplicationMailer
  helper MailerHelper

  layout 'mailers/layout'

  def user_to_instructeur(email)
    @email = email
    subject = "Vous avez été nommé instructeur"

    configure_defaults_for_email(@email)

    mail(to: @email, subject: subject)
  end

  def last_week_overview(instructeur)
    email = instructeur.email
    @subject = 'Votre activité hebdomadaire'
    @overview = instructeur.last_week_overview

    if @overview.present?
      configure_defaults_for_user(instructeur.user)
      mail(to: email, subject: @subject)
    end
  end

  def send_dossier(sender, dossier, recipient)
    @sender = sender
    @dossier = dossier
    subject = "#{sender.email} vous a envoyé le dossier n° #{dossier.id}"

    configure_defaults_for_email(recipient.email)
    mail(to: recipient.email, subject: subject)
  end

  def send_login_token(instructeur, login_token)
    @instructeur = instructeur
    @login_token = login_token
    subject = "Connexion sécurisée à #{Current.application_name}"

    bypass_unverified_mail_protection!

    configure_defaults_for_user(instructeur.user)
    mail(to: instructeur.email, subject: subject)
  end

  def trusted_device_token_renewal(instructeur, renewal_token, valid_until)
    @instructeur = instructeur
    @renewal_token = renewal_token
    @valid_until = valid_until
    subject = "Renouvellement de la connexion sécurisée à #{Current.application_name}"

    configure_defaults_for_user(instructeur.user)
    mail(to: instructeur.email, subject: subject)
  end

  def send_notifications(instructeur, data)
    @data = data
    subject = "Vous avez du nouveau sur vos démarches"

    configure_defaults_for_user(instructeur.user)
    mail(to: instructeur.email, subject: subject)
  end

  def self.critical_email?(action_name)
    action_name.in?(["send_login_token", "trusted_device_token_renewal"])
  end

  def confirm_and_notify_added_instructeur(instructeur, group, current_instructeur_email)
    @instructeur = instructeur
    @group = group
    @current_instructeur_email = current_instructeur_email
    @reset_password_token = instructeur.user.send(:set_reset_password_token)

    subject = if group.procedure.groupe_instructeurs.many?
      "Vous avez été ajouté(e) au groupe \"#{group.label}\" de la démarche \"#{group.procedure.libelle}\""
    else
      "Vous avez été affecté(e) à la démarche \"#{group.procedure.libelle}\""
    end

    bypass_unverified_mail_protection!

    configure_defaults_for_user(instructeur.user)
    mail(to: instructeur.email, subject: subject)
  end
end
