module Manager
  class AdminsGroupsController < Manager::ApplicationController
    def add_admins_group_manager
      emails = (params['emails'].presence || '').split(',').to_json
      emails = JSON.parse(emails).map { EmailSanitizableConcern::EmailSanitizer.sanitize(_1) }

      admins_group_managers, invalid_emails = admins_group.add_admins_group_managers(emails:)

      if invalid_emails.present?
        flash[:alert] = t('.wrong_address',
          count: invalid_emails.size,
          emails: invalid_emails)
      end

      if admins_group_managers.present?
        flash[:notice] = "Les gestionnaires ont bien été affectés au groupe d'administrateurs"

        AdminsGroupMailer
          .notify_added_admins_group_managers(admins_group, admins_group_managers, current_super_admin.email)
          .deliver_later
      end

      redirect_to manager_admins_groups_path(admins_group)
    end

    private

    def admins_group
      @admins_group ||= AdminsGroup.find(params[:id])
    end
  end
end
