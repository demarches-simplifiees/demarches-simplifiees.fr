# Preview all emails at http://localhost:3000/rails/mailers/avis_mailer
class AvisMailerPreview < ActionMailer::Preview
  def avis_invitation
    gestionaire = Gestionnaire.new(id: 1, email: 'jeanmichel.de-chauvigny@exemple.fr')
    avis = Avis.new(id: 1, email: 'test@exemple.fr', claimant: gestionaire)
    avis.dossier = Dossier.new(id: 1)
    avis.dossier.procedure = Procedure.new(libelle: 'Démarche pour faire des marches')
    avis.introduction = 'Il faudrait vérifier le certificat de conformité.'
    AvisMailer.avis_invitation(avis)
  end
end
