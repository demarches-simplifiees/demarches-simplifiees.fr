class Administrations::SessionsController < ApplicationController
  layout "new_application"

  def new
  end

  def destroy
    sign_out :administration if administration_signed_in?
    redirect_to root_path
  end
end
