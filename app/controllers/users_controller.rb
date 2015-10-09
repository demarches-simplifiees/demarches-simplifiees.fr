class UsersController < ApplicationController
  before_action :authenticate_user!

  def current_user_dossier dossier_id=nil
    dossier_id ||= params[:dossier_id]

    current_user.dossiers.find(dossier_id)
  end
end