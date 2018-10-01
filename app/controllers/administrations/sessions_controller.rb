class Administrations::SessionsController < ApplicationController
  layout "new_application"

  def new
  end

  def destroy
    if administration_signed_in?
      sign_out :administration
    end

    redirect_to root_path
  end
end
