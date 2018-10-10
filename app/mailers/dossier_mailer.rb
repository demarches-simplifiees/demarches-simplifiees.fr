class DossierMailer < ApplicationMailer
  layout 'mailers/layout'

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
end
