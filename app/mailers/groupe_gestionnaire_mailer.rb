class GroupeGestionnaireMailer < ApplicationMailer
  layout 'mailers/layout'

  def notify_removed_gestionnaire(groupe_gestionnaire, removed_gestionnaire, current_super_admin_email)
    @groupe_gestionnaire = groupe_gestionnaire
    @current_super_admin_email = current_super_admin_email
    subject = "Vous avez été retiré(e) du groupe d'administrateur \"#{groupe_gestionnaire.name}\""

    mail(to: removed_gestionnaire.email, subject: subject)
  end

  def notify_added_gestionnaires(groupe_gestionnaire, added_gestionnaires, current_super_admin_email)
    added_gestionnaire_emails = added_gestionnaires.map(&:email)
    @groupe_gestionnaire = groupe_gestionnaire
    @current_super_admin_email = current_super_admin_email

    subject = "Vous avez été ajouté(e) en tant que gestionnaire du groupe gestionnaire \"#{groupe_gestionnaire.name}\""

    mail(bcc: added_gestionnaire_emails, subject: subject)
  end
end
