class UsersController < ApplicationController
  before_action :authenticate_user!

  def current_user_dossier dossier_id=nil
    dossier_id ||= params[:dossier_id] || params[:id]

    current_user.dossiers.find(dossier_id)
  end

  def authorized_routes?
    sub_path = "/users/dossiers/#{current_user_dossier.id}"

    redirect_to_root_path 'Le status de votre dossier n\'autorise pas cette URL' unless UserRoutesAuthorizationService.authorized_route?(
        (request.env['PATH_INFO']).gsub(sub_path, ''),
        current_user_dossier.state,
        current_user_dossier.procedure.use_api_carto)
  rescue ActiveRecord::RecordNotFound
    redirect_to_root_path 'Vous n’avez pas accès à ce dossier.'
  end

  private

  def redirect_to_root_path message
    flash.alert = message
    redirect_to url_for root_path
  end
end