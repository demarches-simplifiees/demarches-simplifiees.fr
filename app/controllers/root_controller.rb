class RootController < ApplicationController
  def index

    begin
      route = Rails.application.routes.recognize_path(request.referrer)
    rescue ActionController::RoutingError
      route = Rails.application.routes.recognize_path(new_user_session_path)
    end

    if Features.opensimplif
      unless !user_signed_in? && !administrateur_signed_in? && !gestionnaire_signed_in?
        return redirect_to simplifications_path
      end
    end

    if user_signed_in? && !route[:controller].match('users').nil?
      return redirect_to users_dossiers_path

    elsif administrateur_signed_in? && !route[:controller].match('admin').nil?
      return redirect_to admin_procedures_path

    elsif gestionnaire_signed_in?
      procedure_id = current_gestionnaire.procedure_filter
      if procedure_id.nil?
        procedure_list = current_gestionnaire.procedures

        if procedure_list.count > 0
          return redirect_to backoffice_dossiers_procedure_path(id: procedure_list.first.id)
        else
          flash.alert = "Vous n'avez aucune procédure d'affectée"
        end
      else
        return redirect_to backoffice_dossiers_procedure_path(id: procedure_id)
      end

    elsif user_signed_in?
      return redirect_to users_dossiers_path

    elsif administrateur_signed_in?
      return redirect_to admin_procedures_path

    elsif administration_signed_in?
      return redirect_to administrations_path
    end

    @demo_environment_host = "https://tps-dev.apientreprise.fr" unless Rails.env.development?

    render 'landing'
  end
end
