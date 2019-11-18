class GroupeInstructeurMailerPreview < ActionMailer::Preview
  def add_instructeurs
    groupe = GroupeInstructeur.new(label: 'Val-De-Marne')
    current_instructeur_email = 'admin@dgfip.com'
    instructeurs = Instructeur.limit(2)
    GroupeInstructeurMailer.add_instructeurs(groupe, instructeurs, current_instructeur_email)
  end
end
