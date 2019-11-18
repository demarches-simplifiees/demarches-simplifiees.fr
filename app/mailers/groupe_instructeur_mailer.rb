class GroupeInstructeurMailer < ApplicationMailer
  layout 'mailers/layout'

  def add_instructeurs(group, instructeurs, current_instructeur_email)
    @new_instructeur_emails = instructeurs.map(&:email)
    @group = Procedure.last.defaut_groupe_instructeur
    @current_instructeur_email = current_instructeur_email

    subject = "Ajout d’un instructeur dans le groupe \"#{group.label}\""

    emails = @group.instructeurs.map(&:email)
    mail(bcc: emails, subject: subject)
  end

  def remove_instructeur(group, instructeur, current_instructeur_email)
    @email = instructeur.email
    @group = group
    @current_instructeur_email = current_instructeur_email

    subject = "Suppression d’un instructeur dans le groupe \"#{group.label}\""

    emails = @group.instructeurs.map(&:email)
    mail(bcc: emails, subject: subject)
  end
end
