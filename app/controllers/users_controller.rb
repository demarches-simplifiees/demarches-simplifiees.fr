class UsersController < ApplicationController
  before_action :authenticate_user!

  def index
    redirect_to root_path
  end

  def current_user_dossier dossier_id=nil
    dossier_id ||= params[:dossier_id] || params[:id]

    dossier = Dossier.find(dossier_id)

    return dossier if dossier.owner?(current_user.email) || dossier.invite_by_user?(current_user.email)

    raise ActiveRecord::RecordNotFound
  end

  def authorized_routes? controller
    redirect_to_root_path 'Le status de votre dossier n\'autorise pas cette URL' unless UserRoutesAuthorizationService.authorized_route?(
        controller,
        current_user_dossier)
  rescue ActiveRecord::RecordNotFound
    redirect_to_root_path 'Vous n’avez pas accès à ce dossier.'
  end

  private

  def redirect_to_root_path message
    flash.alert = message
    redirect_to url_for root_path
  end
end