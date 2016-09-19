class RootController < ApplicationController
  def index

    if user_signed_in?
      redirect_to users_dossiers_path

    elsif gestionnaire_signed_in?
      redirect_to backoffice_dossiers_path

    elsif administrateur_signed_in?
      redirect_to admin_procedures_path

    elsif administration_signed_in?
      redirect_to administrations_path

    else
      # @latest_release = Github::Releases.latest
      @latest_release = nil
      render 'landing'
    end
  end
end