class GroupeInstructeurMailerPreview < ActionMailer::Preview
  def remove_instructeurs
    procedure = Procedure.new(id: 1, libelle: 'une superbe procedure')
    groupe = GroupeInstructeur.new(id: 1, label: 'Val-De-Marne', procedure:)
    current_instructeur_email = 'admin@dgfip.com'
    instructeurs = Instructeur.limit(2)
    GroupeInstructeurMailer.remove_instructeurs(groupe, instructeurs, current_instructeur_email)
  end

  def remove_instructeur
    procedure = Procedure.new(id: 1, libelle: 'une superbe procedure')
    groupe = GroupeInstructeur.new(id: 1, label: 'Val-De-Marne', procedure:)
    current_instructeur_email = 'admin@dgfip.com'
    instructeurs = Instructeur.limit(2)
    GroupeInstructeurMailer.remove_instructeur(groupe, instructeurs, current_instructeur_email)
  end
end
