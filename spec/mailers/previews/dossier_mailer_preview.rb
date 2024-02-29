# Preview all emails at http://localhost:3000/rails/mailers/dossier_mailer
class DossierMailerPreview < ActionMailer::Preview
  def notify_new_draft
    DossierMailer.with(dossier: draft).notify_new_draft
  end

  def notify_new_answer
    DossierMailer.with(commentaire: commentaire(on: draft)).notify_new_answer
  end

  def notify_pending_correction
    commentaire = commentaire(on: dossier_en_construction(sva_svr_decision: :sva)).tap { _1.build_dossier_correction(kind: :correction) }
    DossierMailer.with(commentaire:).notify_pending_correction
  end

  def notify_pending_correction_sva_correction
    commentaire = commentaire(on: dossier_en_construction(sva_svr_decision: :sva)).tap { _1.build_dossier_correction(kind: :correction) }
    DossierMailer.with(commentaire:).notify_pending_correction
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

  def notify_termine_near_deletion_to_user
    DossierMailer.notify_near_deletion_to_user([dossier_accepte], usager_email)
  end

  def notify_termine_near_deletion_to_user_multiple
    DossierMailer.notify_near_deletion_to_user([dossier_accepte, dossier_accepte], usager_email)
  end

  def notify_termine_near_deletion_to_administration
    DossierMailer.notify_near_deletion_to_administration([dossier_accepte, dossier_accepte], administration_email)
  end

  def notify_brouillon_deletion
    DossierMailer.notify_brouillon_deletion([dossier.hash_for_deletion_mail], usager_email)
  end

  def notify_brouillons_deletion
    dossier_hashes = [dossier, dossier].map(&:hash_for_deletion_mail)
    DossierMailer.notify_brouillon_deletion(dossier_hashes, usager_email)
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

  def notify_transfer
    DossierMailer.notify_transfer(transfer)
  end

  private

  def usager_email
    "usager@example.com"
  end

  def administration_email
    "administration@example.com"
  end

  def user
    User.new(email: "usager@example.com", locale: I18n.locale)
  end

  def deleted_dossier
    DeletedDossier.new(dossier_id: 1, procedure: procedure)
  end

  def draft
    Dossier.new(id: 47882, state: :brouillon, procedure: procedure, user: user)
  end

  def dossier
    Dossier.new(id: 47882, state: :en_instruction, procedure: procedure, user: user)
  end

  def dossier_en_construction(sva_svr_decision: nil)
    local_procedure = procedure

    dossier = Dossier.new(id: 47882, state: :en_construction, procedure: local_procedure, user: user)

    if sva_svr_decision
      local_procedure.sva_svr = { decision: sva_svr_decision, period: 2, unit: :months }
      dossier.sva_svr_decision_on = 10.days.from_now.to_date
    end

    dossier
  end

  def dossier_accepte
    Dossier.new(id: 47882, state: :accepte, procedure: procedure, user: user)
  end

  def procedure
    Procedure.new(id: 1234, libelle: 'Dotation d’Équipement des Territoires Ruraux - Exercice 2019', service: service, logo: Rack::Test::UploadedFile.new('spec/fixtures/files/logo_test_procedure.png', 'image/png'), auto_archive_on: Time.zone.today + Dossier::REMAINING_DAYS_BEFORE_CLOSING.days)
  end

  def service
    Service.new(
      nom: 'Direction du Territoire des Vosges',
      email: 'prms@ddt.vosges.gouv.fr',
      telephone: '01 34 22 33 85',
      horaires: 'Du lundi au vendredi, de 9 h à 18 h'
    )
  end

  def transfer
    DossierTransfer.new(email: usager_email, dossiers: [dossier, dossier_accepte])
  end

  def commentaire(on:)
    dossier = on
    Commentaire.new(id: 7726, body: "Bonjour, Vous avez commencé le dépôt d’un dossier pour une subvention DETR /DSIL. Dans le cas où votre opération n’aurait pas connu un commencement d’exécution, vous êtes encouragé(e) à redéposer un nouveau dossier sur le formulaire de cette année.\nLa DDT", dossier: dossier)
  end
end
