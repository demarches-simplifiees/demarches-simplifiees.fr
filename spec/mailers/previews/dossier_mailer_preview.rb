# Preview all emails at http://localhost:3000/rails/mailers/dossier_mailer
class DossierMailerPreview < ActionMailer::Preview
  def notify_new_draft
    DossierMailer.notify_new_draft(draft)
  end

  def notify_new_answer
    DossierMailer.notify_new_answer(dossier)
  end

  def notify_revert_to_instruction
    DossierMailer.notify_revert_to_instruction(dossier)
  end

  def notify_brouillon_near_deletion
    DossierMailer.notify_brouillon_near_deletion([dossier], usager_email)
  end

  def notify_brouillons_near_deletion
    DossierMailer.notify_brouillon_near_deletion([dossier, dossier], usager_email)
  end

  def notify_en_construction_near_deletion_to_user
    DossierMailer.notify_near_deletion_to_user([dossier_en_construction], usager_email)
  end

  def notify_en_construction_near_deletion_to_administration
    DossierMailer.notify_near_deletion_to_administration([dossier_en_construction, dossier_en_construction], administration_email)
  end

  def notify_en_instruction_near_deletion_to_user
    DossierMailer.notify_near_deletion_to_user([dossier_en_instruction], usager_email)
  end

  def notify_en_instruction_near_deletion_to_administration
    DossierMailer.notify_near_deletion_to_administration([dossier_en_instruction, dossier_en_instruction], administration_email)
  end

  def notify_brouillon_deletion
    DossierMailer.notify_brouillon_deletion([dossier.hash_for_deletion_mail], usager_email)
  end

  def notify_brouillons_deletion
    dossier_hashes = [dossier, dossier].map(&:hash_for_deletion_mail)
    DossierMailer.notify_brouillon_deletion(dossier_hashes, usager_email)
  end

  def notify_deletion_to_user
    DossierMailer.notify_deletion_to_user(deleted_dossier, usager_email)
  end

  def notify_deletion_to_administration
    DossierMailer.notify_deletion_to_administration(deleted_dossier, administration_email)
  end

  def notify_automatic_deletion_to_user
    DossierMailer.notify_automatic_deletion_to_user([deleted_dossier, deleted_dossier], usager_email)
  end

  def notify_automatic_deletion_to_administration
    DossierMailer.notify_automatic_deletion_to_administration([deleted_dossier, deleted_dossier], administration_email)
  end

  def notify_brouillon_not_submitted
    DossierMailer.notify_brouillon_not_submitted(draft)
  end

  private

  def usager_email
    "usager@example.com"
  end

  def administration_email
    "administration@example.com"
  end

  def deleted_dossier
    DeletedDossier.new(dossier_id: 1, procedure: procedure)
  end

  def draft
    Dossier.new(id: 47882, procedure: procedure, user: User.new(email: "usager@example.com"))
  end

  def dossier
    Dossier.new(id: 47882, state: :en_instruction, procedure: procedure, user: User.new(email: "usager@example.com"))
  end

  def dossier_en_construction
    Dossier.new(id: 47882, state: :en_construction, procedure: procedure, user: User.new(email: "usager@example.com"))
  end

  def dossier_en_instruction
    Dossier.new(id: 47882, state: :en_instruction, procedure: procedure, user: User.new(email: "usager@example.com"))
  end

  def procedure
    Procedure.new(id: 1234, libelle: 'Dotation d’Équipement des Territoires Ruraux - Exercice 2019', service: service, logo: Rack::Test::UploadedFile.new("./spec/fixtures/files/logo_test_procedure.png", 'image/png'), auto_archive_on: Time.zone.today + Dossier::REMAINING_DAYS_BEFORE_CLOSING.days)
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
