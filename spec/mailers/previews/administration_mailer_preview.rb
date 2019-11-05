class AdministrationMailerPreview < ActionMailer::Preview
  def dubious_procedures
    procedures_and_champs = [
      [procedure_1, [TypeDeChamp.new(libelle: 'iban'), TypeDeChamp.new(libelle: 'religion')]],
      [procedure_2, [TypeDeChamp.new(libelle: 'iban'), TypeDeChamp.new(libelle: 'numéro de carte bleu')]]
    ]
    AdministrationMailer.dubious_procedures(procedures_and_champs)
  end

  def invite_admin
    AdministrationMailer.invite_admin(administrateur, "12345678", 0)
  end

  def invite_admin_whose_already_has_an_account
    AdministrationMailer.invite_admin(administrateur, nil, 0)
  end

  def refuse_admin
    AdministrationMailer.refuse_admin('bad_admin@pipo.com')
  end

  def new_admin
    administration = Administration.new(email: 'superadmin@demarches-simplifiees.fr')
    AdministrationMailer.new_admin_email(administrateur, administration)
  end

  def dossier_expiration_summary
    expiring_dossiers = [Dossier.new(id: 100, procedure: procedure_1)]
    expired_dossiers = [Dossier.new(id: 100, procedure: procedure_2)]
    AdministrationMailer.dossier_expiration_summary(expiring_dossiers, expired_dossiers)
  end

  private

  def procedure_1
    Procedure.new(id: 10, libelle: "Démarche des marches", administrateurs: [administrateur])
  end

  def procedure_2
    Procedure.new(id: 20, libelle: "Démarche pieds", administrateurs: [administrateur])
  end

  def administrateur
    Administrateur.new(id: 111, email: "chef.de.service@administration.gouv.fr")
  end
end
