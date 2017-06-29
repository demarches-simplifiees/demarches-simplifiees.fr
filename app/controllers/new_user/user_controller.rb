module NewUser
  class UserController < ApplicationController
    before_action :authenticate_user!
  end
end
