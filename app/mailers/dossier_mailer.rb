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

  def notify_deletion_to_user(deleted_dossier, to_email)
    @deleted_dossier = deleted_dossier
    subject = "Votre dossier nº #{@deleted_dossier.dossier_id} a bien été supprimé"

    mail(to: to_email, subject: subject)
  end

  def notify_deletion_to_administration(deleted_dossier, to_email)
    @deleted_dossier = deleted_dossier
    subject = "Le dossier nº #{@deleted_dossier.dossier_id} a été supprimé à la demande de l'usager"

    mail(to: to_email, subject: subject)
  end

  def notify_unhide_to_user(dossier)
    @dossier = dossier
    subject = "Votre dossier nº #{@dossier.id} n'a pas pu être supprimé"

    mail(to: dossier.user.email, subject: subject)
  end

  def notify_undelete_to_user(dossier)
    @dossier = dossier
    @dossier_kind = dossier.brouillon? ? 'brouillon' : 'dossier'
    @subject = "Votre #{@dossier_kind} nº #{@dossier.id} est à nouveau accessible"

    mail(to: dossier.user.email, subject: @subject)
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

  def notify_near_deletion(user, dossiers)
    @subject = default_i18n_subject(count: dossiers.count)
    @dossiers = dossiers

    mail(to: user.email, subject: @subject)
  end
end
