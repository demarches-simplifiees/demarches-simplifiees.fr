module AdminsGroupManagers
  class AdminsGroupManagerController < ApplicationController
    before_action :authenticate_admins_group_manager!

    def nav_bar_profile
      :admins_group_manager
    end
  end
end
