module AdminsGroupManagers
  class AdminsGroupsController < AdminsGroupManagerController
    def index
      @admins_groups = admins_groups
    end

    private

    def admins_groups
      admins_group_ids = current_admins_group_manager.admins_group_ids
      AdminsGroup.where(id: admins_group_ids.compact.uniq)
    end
  end
end
