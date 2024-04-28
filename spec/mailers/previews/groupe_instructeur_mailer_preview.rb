# frozen_string_literal: true

class GroupeInstructeurMailerPreview < ActionMailer::Preview
  def notify_removed_instructeur
    procedure = Procedure.new(id: 1, libelle: 'une superbe procedure')
    groupe = GroupeInstructeur.new(id: 1, label: 'Val-De-Marne', procedure:)
    current_instructeur_email = 'admin@dgfip.com'
    instructeur = Instructeur.last
    GroupeInstructeurMailer.notify_removed_instructeur(groupe, instructeur, current_instructeur_email)
  end

  def notify_added_instructeurs
    procedure = Procedure.new(id: 1, libelle: 'une superbe procedure')
    groupe = GroupeInstructeur.new(id: 1, label: 'Val-De-Marne', procedure:)
    current_instructeur_email = 'admin@dgfip.com'
    instructeurs = Instructeur.limit(2)
    GroupeInstructeurMailer.notify_added_instructeurs(groupe, instructeurs, current_instructeur_email)
  end
end
