class AdminController < ApplicationController

  def index
    redirect_to(controller: '/administrateurs/sessions', action: :new) unless administrateur_signed_in?
    redirect_to (admin_procedures_path)
  end
end
