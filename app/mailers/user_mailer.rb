# Preview all emails at http://localhost:3000/rails/mailers/user_mailer
class UserMailer < ApplicationMailer
  helper MailerHelper

  layout 'mailers/layout'

  def new_account_warning(user, procedure = nil)
    @user = user
    @subject = "Demande de création de compte"
    @procedure = procedure

    mail(to: user.email, subject: @subject, procedure: @procedure)
  end

  def ask_for_merge(user, requested_email)
    @user = user
    @requested_email = requested_email
    @subject = "Fusion de compte"

    mail(to: requested_email, subject: @subject)
  end

  def france_connect_merge_confirmation(email, merge_token, merge_token_created_at)
    @merge_token = merge_token
    @merge_token_created_at = merge_token_created_at
    @subject = "Veuillez confirmer la fusion de compte"

    mail(to: email, subject: @subject)
  end

  def invite_instructeur(user, reset_password_token)
    @reset_password_token = reset_password_token
    @user = user
    subject = "Activez votre compte instructeur"

    mail(to: user.email,
      subject: subject,
      reply_to: CONTACT_EMAIL)
  end

  def send_archive(administrateur_or_instructeur, procedure, archive)
    @archive = archive
    @procedure = procedure
    @archive_url = case administrateur_or_instructeur
    when Instructeur then instructeur_archives_url(@procedure)
    when Administrateur then admin_procedure_archives_url(@procedure)
    else raise ArgumentError("send_archive expect either an Instructeur or an Administrateur")
    end
    @procedure_url = case administrateur_or_instructeur
    when Instructeur then instructeur_procedure_url(@procedure.id)
    when Administrateur then admin_procedure_url(@procedure)
    else raise ArgumentError("send_archive expect either an Instructeur or an Administrateur")
    end
    subject = "Votre archive est disponible"

    mail(to: administrateur_or_instructeur.email, subject: subject)
  end
end
