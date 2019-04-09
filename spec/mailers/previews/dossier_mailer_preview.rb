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

  def notify_revert_to_instruction
    DossierMailer.notify_revert_to_instruction(dossier)
  end

  private

  def deleted_dossier
    DeletedDossier.new(dossier_id: 1, procedure: procedure)
  end

  def dossier
    Dossier.new(id: 1, procedure: procedure, user: User.new(email: "usager@example.com"))
  end

  def procedure
    Procedure.new(libelle: 'Démarche pour des marches')
  end
end
