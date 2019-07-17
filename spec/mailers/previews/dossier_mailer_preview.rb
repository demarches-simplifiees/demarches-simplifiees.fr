# Preview all emails at http://localhost:3000/rails/mailers/dossier_mailer
class DossierMailerPreview < ActionMailer::Preview
  def notify_new_draft
    DossierMailer.notify_new_draft(draft)
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

  def draft
    Dossier.new(id: 47882, procedure: procedure, user: User.new(email: "usager@example.com"))
  end

  def dossier
    Dossier.new(id: 47882, state: :en_instruction, procedure: procedure, user: User.new(email: "usager@example.com"))
  end

  def procedure
    Procedure.new(libelle: 'Dotation d’Équipement des Territoires Ruraux - Exercice 2019', service: service, logo: Rack::Test::UploadedFile.new("./spec/fixtures/files/logo_test_procedure.png", 'image/png'))
  end

  def service
    Service.new(
      nom: 'Direction du Territoire des Vosges',
      email: 'prms@ddt.vosges.gouv.fr',
      telephone: '01 34 22 33 85',
      horaires: 'Du lundi au vendredi, de 9 h à 18 h'
    )
  end
end
