class AdminsGroupMailerPreview < ActionMailer::Preview
  def notify_added_admins_group_managers
    admins_group = AdminsGroup.new(name: 'un groupe d\'admin')
    current_super_admin_email = 'admin@dgfip.com'
    admins_group_managers = [AdminsGroupManager.new(user: user)]
    AdminsGroupMailer.notify_added_admins_group_managers(admins_group, admins_group_managers, current_super_admin_email)
  end

  private

  def user
    User.new(id: 10, email: 'test@exemple.fr')
  end
end
