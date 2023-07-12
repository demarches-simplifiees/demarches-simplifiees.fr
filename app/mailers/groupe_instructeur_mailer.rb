class GroupeInstructeurMailer < ApplicationMailer
  layout 'mailers/layout'

  def remove_instructeurs(group, removed_instructeurs, current_instructeur_email)
    @removed_instructeur_emails = removed_instructeurs.map(&:email)
    @group = group
    @current_instructeur_email = current_instructeur_email

    subject = "Suppression d’un instructeur dans le groupe \"#{group.label}\""

    emails = @group.instructeurs.map(&:email)
    mail(bcc: emails, subject: subject)
  end
end
