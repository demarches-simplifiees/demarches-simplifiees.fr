# Preview all emails at http://localhost:3000/rails/mailers/dossier_mailer
class DossierMailerPreview < ActionMailer::Preview
  def notify_new_draft
    DossierMailer.notify_new_draft(dossier)
  end

  def notify_new_answer
    DossierMailer.notify_new_answer(dossier)
  end

  def notify_deletion_to_user
    DossierMailer.notify_deletion_to_user(deleted_dossier, "user@ds.fr")
  end

  def notify_deletion_to_administration
    DossierMailer.notify_deletion_to_administration(deleted_dossier, "admin@ds.fr")
  end

  private

  def deleted_dossier
    DeletedDossier.last || DeletedDossier.new(dossier_id: 1, procedure: test_procedure)
  end

  def dossier
    Dossier.last || Dossier.new(id: 1, procedure: test_procedure)
  end

  def test_procedure
    Procedure.new(libelle: 'Démarche pour des marches')
  end
end
