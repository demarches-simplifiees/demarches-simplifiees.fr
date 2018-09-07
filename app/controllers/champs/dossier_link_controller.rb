class Champs::DossierLinkController < ApplicationController
  before_action :authenticate_logged_user!

  def show
    if params[:dossier].key?(:champs_attributes)
      @dossier_id = params[:dossier][:champs_attributes][params[:position]][:value]
    else
      @dossier_id = params[:dossier][:champs_private_attributes][params[:position]][:value]
    end
  end
end
