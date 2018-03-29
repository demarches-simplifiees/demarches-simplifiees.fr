class UsersController < ApplicationController
  before_action :authenticate_user!

  def index
    redirect_to root_path
  end

  def current_user_dossier(dossier_id = nil)
    dossier_id ||= params[:dossier_id] || params[:id]

    dossier = Dossier.find(dossier_id)

    if !dossier.owner_or_invite?(current_user)
      raise ActiveRecord::RecordNotFound
    end

    dossier
  end

  def authorized_routes?(controller)
    if !UserRoutesAuthorizationService.authorized_route?(controller, current_user_dossier)
      redirect_to_root_path 'Le statut de votre dossier n\'autorise pas cette URL'
    end

  rescue ActiveRecord::RecordNotFound
    redirect_to_root_path 'Vous n’avez pas accès à ce dossier.'
  end

  private

  def redirect_to_root_path(message)
    flash.alert = message
    redirect_to url_for root_path
  end
end
