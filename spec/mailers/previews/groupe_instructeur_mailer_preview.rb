class GroupeInstructeurMailerPreview < ActionMailer::Preview
  def add_instructeurs
    procedure = Procedure.new(id: 1, libelle: 'une superbe procedure')
    groupe = GroupeInstructeur.new(id: 1, label: 'Val-De-Marne', procedure:)
    current_instructeur_email = 'admin@dgfip.com'
    instructeurs = Instructeur.limit(2)
    GroupeInstructeurMailer.add_instructeurs(groupe, instructeurs, current_instructeur_email)
  end
end
