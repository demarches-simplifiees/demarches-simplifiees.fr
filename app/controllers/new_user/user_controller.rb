module NewUser
  class UserController < ApplicationController
    layout "new_application"

    before_action :authenticate_user!
  end
end
