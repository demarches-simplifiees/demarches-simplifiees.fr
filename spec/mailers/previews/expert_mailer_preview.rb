# frozen_string_literal: true

class ExpertMailerPreview < ActionMailer::Preview
  def send_dossier_decision
    procedure = Procedure.new(id: 1, libelle: 'Démarche pour faire des marches')
    dossier = Dossier.new(id: 1, procedure: procedure)

    instructeur = Instructeur.new(id: 1, user: User.new(email: 'jeanmichel.de-chauvigny@exemple.fr'))

    expert = Expert.new(id: 1, user: User.new(email: 'moussa.kanga@exemple.fr'))
    experts_procedure = ExpertsProcedure.new(expert: expert, procedure: procedure, allow_decision_access: true)

    avis = Avis.new(id: 1, email: 'test@exemple.fr', claimant: instructeur, dossier:, experts_procedure:, expert:)

    ExpertMailer.send_dossier_decision_v2(avis)
  end
end
