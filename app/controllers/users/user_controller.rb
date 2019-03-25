module Users
  class UserController < ApplicationController
    before_action :authenticate_user!

    def nav_bar_profile
      :user
    end
  end
end
