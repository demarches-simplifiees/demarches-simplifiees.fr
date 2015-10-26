class RootController < ApplicationController
  def index

    if user_signed_in?
      redirect_to users_dossiers_path
    elsif gestionnaire_signed_in?
      redirect_to backoffice_path
    elsif administrateur_signed_in?
      redirect_to admin_procedures_path
    else
      redirect_to new_user_session_path
    end
  end
end