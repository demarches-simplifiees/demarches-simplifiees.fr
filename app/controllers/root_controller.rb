class RootController < ApplicationController
  def index
    route = Rails.application.routes.recognize_path(request.referrer)

    if user_signed_in? && !route[:controller].match('users').nil?
      return redirect_to users_dossiers_path
    end

    if gestionnaire_signed_in?
      redirect_to backoffice_dossiers_procedure_path(id: current_gestionnaire.procedure_filter)

    elsif user_signed_in?
      redirect_to users_dossiers_path

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