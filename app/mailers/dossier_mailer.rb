class DossierMailer < ApplicationMailer
  layout 'mailers/layout'

  def notify_deletion_to_user(deleted_dossier, to_email)
    @deleted_dossier = deleted_dossier
    mail(to: to_email, subject: "Votre dossier n° #{@deleted_dossier.dossier_id} a bien été supprimé")
  end

  def notify_deletion_to_administration(deleted_dossier, to_email)
    @deleted_dossier = deleted_dossier
    mail(to: to_email, subject: "Le dossier n° #{@deleted_dossier.dossier_id} a été supprimé à la demande de l'usager")
  end
end
