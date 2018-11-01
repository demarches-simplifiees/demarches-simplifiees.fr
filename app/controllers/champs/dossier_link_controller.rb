class Champs::DossierLinkController < ApplicationController
  before_action :authenticate_account!

  def show
    @position = params[:position]

    if params[:dossier].key?(:champs_attributes)
      @dossier_id = params[:dossier][:champs_attributes][params[:position]][:value]
    else
      @dossier_id = params[:dossier][:champs_private_attributes][params[:position]][:value]
    end
  end
end
