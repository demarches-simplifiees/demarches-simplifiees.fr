class ExpertMailerPreview < ActionMailer::Preview
  def send_dossier_decision
    procedure = Procedure.new(libelle: 'Démarche pour faire des marches')
    dossier = Dossier.new(id: 1, procedure: procedure)
    instructeur = Instructeur.new(id: 1, user: User.new(email: 'jeanmichel.de-chauvigny@exemple.fr'))
    expert = Expert.new(id: 1, user: User.new('moussa.kanga@exemple.fr'))
    experts_procedure = ExpertsProcedure.new(expert: expert, procedure: procedure, allow_decision_access: true)
    avis = Avis.new(id: 1, email: 'test@exemple.fr', dossier: dossier, claimant: instructeur, experts_procedure: experts_procedure)
    ExpertMailer.send_dossier_decision(avis.id)
  end
end
