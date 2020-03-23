# Preview all emails at http://localhost:3000/rails/mailers/dossier_mailer
class DossierMailer < ApplicationMailer
  helper ServiceHelper
  helper MailerHelper

  layout 'mailers/layout'

  def notify_new_draft(dossier)
    @dossier = dossier
    @service = dossier.procedure.service
    @logo_url = attach_logo(dossier.procedure)

    subject = "Retrouvez votre brouillon pour la démarche « #{dossier.procedure.libelle} »"

    mail(from: NO_REPLY_EMAIL, to: dossier.user.email, subject: subject) do |format|
      format.html { render layout: 'mailers/notifications_layout' }
    end
  end

  def notify_new_answer(dossier)
    @dossier = dossier
    @service = dossier.procedure.service
    @logo_url = attach_logo(dossier.procedure)

    subject = "Nouveau message pour votre dossier nº #{dossier.id} (#{dossier.procedure.libelle})"

    mail(from: NO_REPLY_EMAIL, to: dossier.user.email, subject: subject) do |format|
      format.html { render layout: 'mailers/notifications_layout' }
    end
  end

  def notify_revert_to_instruction(dossier)
    @dossier = dossier
    @service = dossier.procedure.service
    @logo_url = attach_logo(dossier.procedure)

    subject = "Votre dossier nº #{@dossier.id} est en train d'être réexaminé"

    mail(from: NO_REPLY_EMAIL, to: dossier.user.email, subject: subject) do |format|
      format.html { render layout: 'mailers/notifications_layout' }
    end
  end

  def notify_brouillon_near_deletion(dossiers, to_email)
    @subject = default_i18n_subject(count: dossiers.count)
    @dossiers = dossiers

    mail(to: to_email, subject: @subject)
  end

  def notify_brouillon_deletion(dossier_hashes, to_email)
    @subject = default_i18n_subject(count: dossier_hashes.count)
    @dossier_hashes = dossier_hashes

    mail(to: to_email, subject: @subject)
  end

  def notify_deletion_to_user(deleted_dossier, to_email)
    @subject = default_i18n_subject(dossier_id: deleted_dossier.dossier_id)
    @deleted_dossier = deleted_dossier

    mail(to: to_email, subject: @subject)
  end

  def notify_deletion_to_administration(deleted_dossier, to_email)
    @subject = default_i18n_subject(dossier_id: deleted_dossier.dossier_id)
    @deleted_dossier = deleted_dossier

    mail(to: to_email, subject: @subject)
  end

  def notify_automatic_deletion_to_user(deleted_dossiers, to_email)
    @subject = default_i18n_subject(count: deleted_dossiers.count)
    @deleted_dossiers = deleted_dossiers

    mail(to: to_email, subject: @subject)
  end

  def notify_automatic_deletion_to_administration(deleted_dossiers, to_email)
    @subject = default_i18n_subject(count: deleted_dossiers.count)
    @deleted_dossiers = deleted_dossiers

    mail(to: to_email, subject: @subject)
  end

  def notify_en_construction_near_deletion_to_user(dossiers, to_email)
    @subject = default_i18n_subject(count: dossiers.count)
    @dossiers = dossiers

    mail(to: to_email, subject: @subject)
  end

  def notify_en_construction_near_deletion_to_administration(dossiers, to_email)
    @subject = default_i18n_subject(count: dossiers.count)
    @dossiers = dossiers

    mail(to: to_email, subject: @subject)
  end

  def notify_dossier_not_submitted(dossier)
    @subject = "Attention : votre dossier n'est pas déposé."
    @dossier = dossier

    mail(to: dossier.user.email, subject: @subject)
  end

  def notify_groupe_instructeur_changed(instructeur, dossier)
    @subject = "Un dossier a changé de groupe instructeur"
    @dossier_id = dossier.id
    @demarche = dossier.procedure.libelle

    mail(from: NO_REPLY_EMAIL, to: instructeur.email, subject: @subject)
  end
end
