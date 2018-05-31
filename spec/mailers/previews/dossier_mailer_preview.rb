# Preview all emails at http://localhost:3000/rails/mailers/dossier_mailer
class DossierMailerPreview < ActionMailer::Preview
  def notify_deletion_to_user
    DossierMailer.notify_deletion_to_user(DeletedDossier.last, "user@ds.fr")
  end

  def notify_deletion_to_administration
    DossierMailer.notify_deletion_to_administration(DeletedDossier.last, "admin@ds.fr")
  end
end
