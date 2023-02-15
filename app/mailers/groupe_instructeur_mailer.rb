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

  def notify_removed_instructeur(group, removed_instructeur, current_instructeur_email)
    @group = group
    @current_instructeur_email = current_instructeur_email
    @still_assigned_to_procedure = removed_instructeur.in?(group.procedure.instructeurs)
    subject = if @still_assigned_to_procedure
      "Vous avez été retiré du groupe \"#{group.label}\" de la démarche \"#{group.procedure.libelle}\""
    else
      "Vous avez été désaffecté de la démarche \"#{group.procedure.libelle}\""
    end

    mail(to: removed_instructeur.email, subject: subject)
  end
end
