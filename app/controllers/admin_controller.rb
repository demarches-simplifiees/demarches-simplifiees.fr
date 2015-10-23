class AdminController < ApplicationController

  def index
    redirect_to(controller: '/administrateurs/sessions', action: :new) unless administrateur_signed_in?
  end
end
