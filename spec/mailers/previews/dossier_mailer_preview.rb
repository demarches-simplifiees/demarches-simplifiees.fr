# Preview all emails at http://localhost:3000/rails/mailers/dossier_mailer
class DossierMailerPreview < ActionMailer::Preview
  def notify_new_draft
    DossierMailer.notify_new_draft(Dossier.last)
  end

  def notify_new_answer
    DossierMailer.notify_new_answer(Dossier.last)
  end

  def notify_inbound_error
    DossierMailer.notify_inbound_error("user@ds.fr")
  end

  def notify_deletion_to_user
    DossierMailer.notify_deletion_to_user(DeletedDossier.last, "user@ds.fr")
  end

  def notify_deletion_to_administration
    DossierMailer.notify_deletion_to_administration(DeletedDossier.last, "admin@ds.fr")
  end
end
