# Preview all emails at http://localhost:3000/rails/mailers/avis_mailer
class AvisMailerPreview < ActionMailer::Preview
  def avis_invitation
    gestionaire = Instructeur.new(id: 1, user: User.new(email: 'jeanmichel.de-chauvigny@exemple.fr'))
    avis = Avis.new(id: 1, email: 'test@exemple.fr', claimant: gestionaire)
    targeted_link = TargetedUserLink.build(target_model: avis, user: avis.expert.user, target_context: :avis)
    avis.dossier = Dossier.new(id: 1)
    avis.dossier.procedure = Procedure.new(libelle: 'Démarche pour faire des marches')
    avis.introduction = 'Il faudrait vérifier le certificat de conformité.'
    AvisMailer.avis_invitation(avis, targeted_link)
  end
end
