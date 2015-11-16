class AdminController < ApplicationController
  before_action :authenticate_administrateur!

  def index
    redirect_to (admin_procedures_path)
  end
end
