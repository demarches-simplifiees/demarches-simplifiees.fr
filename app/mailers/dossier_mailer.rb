# Preview all emails at http://localhost:3000/rails/mailers/dossier_mailer
class DossierMailer < ApplicationMailer
  include ServiceHelper

  layout 'mailers/layout'

  def notify_new_draft(dossier)
    @dossier = dossier
    subject = "Retrouvez votre brouillon pour la démarche \"#{dossier.procedure.libelle}\""

    mail(to: dossier.user.email, subject: subject)
  end

  def notify_new_answer(dossier)
    @dossier = dossier
    email = dossier.user.email
    reply_to = email_for_reply_to(dossier.procedure.service)
    subject = "Nouveau message pour votre dossier nº #{dossier.id}"

    mail(to: email, subject: subject, reply_to: reply_to) do |format|
      format.html { render layout: 'mailers/notification' }
    end
  end

  def notify_deletion_to_user(deleted_dossier, to_email)
    @deleted_dossier = deleted_dossier
    subject = "Votre dossier n° #{@deleted_dossier.dossier_id} a bien été supprimé"

    mail(to: to_email, subject: subject)
  end

  def notify_deletion_to_administration(deleted_dossier, to_email)
    @deleted_dossier = deleted_dossier
    subject = "Le dossier n° #{@deleted_dossier.dossier_id} a été supprimé à la demande de l'usager"

    mail(to: to_email, subject: subject)
  end

  def notify_unhide_to_user(dossier)
    @dossier = dossier
    subject = "Votre dossier n° #{@dossier.id} n'a pas pu être supprimé"

    mail(to: dossier.user.email, subject: subject)
  end

  def notify_undelete_to_user(dossier)
    @dossier = dossier
    @dossier_kind = dossier.brouillon? ? 'brouillon' : 'dossier'
    @subject = "Votre #{@dossier_kind} n° #{@dossier.id} est à nouveau accessible"

    mail(to: dossier.user.email, subject: @subject)
  end

  def notify_unmigrated_to_user(dossier, new_procedure)
    @dossier = dossier
    @dossier_kind = dossier.brouillon? ? 'brouillon' : 'dossier'
    @subject = "Changement de procédure pour votre #{@dossier_kind} n° #{@dossier.id}"
    @new_procedure = new_procedure

    mail(to: dossier.user.email, subject: @subject)
  end

  def notify_revert_to_instruction(dossier)
    @dossier = dossier
    @subject = "Votre dossier n° #{@dossier.id} est en train d'être réexaminé"

    mail(to: dossier.user.email, subject: @subject)
  end
end
