module NewUser
  class UserController < ApplicationController
    layout "new_application"

    before_action :authenticate_user!

    def nav_bar_profile
      :user
    end
  end
end
