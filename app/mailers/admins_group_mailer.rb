class AdminsGroupMailer < ApplicationMailer
  layout 'mailers/layout'

  def notify_added_admins_group_managers(admins_group, added_admins_group_managers, current_super_admin_email)
    added_admins_group_manager_emails = added_admins_group_managers.map(&:email)
    @admins_group = admins_group
    @current_super_admin_email = current_super_admin_email

    subject = "Vous avez été ajouté(e) en tant que gestionnaire du groupe d'administrateur \"#{admins_group.name}\""

    mail(bcc: added_admins_group_manager_emails, subject: subject)
  end
end
