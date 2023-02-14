class GroupeInstructeurMailer < ApplicationMailer
  layout 'mailers/layout'

  def notify_group_when_instructeurs_removed(group, removed_instructeurs, current_instructeur_email)
    @removed_instructeur_emails = removed_instructeurs.map(&:email)
    @group = group
    @current_instructeur_email = current_instructeur_email

    subject = "Suppression d’un instructeur dans le groupe \"#{group.label}\""

    emails = @group.instructeurs.map(&:email)
    mail(bcc: emails, subject: subject)
  end

  def notify_removed_instructeurs(group, removed_instructeurs, current_instructeur_email)
    removed_instructeur_emails = removed_instructeurs.map(&:email)
    @group = group
    @current_instructeur_email = current_instructeur_email

    subject = "Vous avez été retiré du groupe \"#{group.label}\" de la démarche \"#{group.procedure.libelle}\""

    mail(bcc: removed_instructeur_emails, subject: subject)
  end
end
