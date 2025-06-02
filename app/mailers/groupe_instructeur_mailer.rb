# frozen_string_literal: true

class GroupeInstructeurMailer < ApplicationMailer
  layout 'mailers/layout'

  def notify_removed_instructeur(group, removed_instructeur, current_instructeur_email)
    @group = group
    @current_instructeur_email = current_instructeur_email
    @still_assigned_to_procedure = removed_instructeur.in?(group.procedure.instructeurs)
    subject = if @still_assigned_to_procedure
      "Vous avez été retiré(e) du groupe \"#{group.label}\" de la démarche \"#{group.procedure.libelle}\""
    else
      "Vous avez été désaffecté(e) de la démarche \"#{group.procedure.libelle}\""
    end

    mail(to: removed_instructeur.email, subject: subject)
  end

  def notify_added_instructeurs(group, added_instructeurs, current_instructeur_email)
    added_instructeur_emails = added_instructeurs.map(&:email)
    @group = group
    @current_instructeur_email = current_instructeur_email

    subject = if group.procedure.groupe_instructeurs.many?
      "Vous avez été ajouté(e) au groupe « #{group.label} » de la démarche « #{group.procedure.libelle} »"
    else
      "Vous avez été affecté(e) à la démarche « #{group.procedure.libelle} »"
    end

    mail(bcc: added_instructeur_emails, subject: subject)
  end

  def self.critical_email?(action_name)
    false
  end
end
