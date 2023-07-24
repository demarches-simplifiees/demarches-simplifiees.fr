module Administrateurs
  class AdministrateurController < ApplicationController
    before_action :authenticate_administrateur!
    before_action :alert_for_missing_siret_service
    helper_method :administrateur_as_manager?

    def nav_bar_profile
      :administrateur
    end

    def retrieve_procedure
      id = params[:procedure_id] || params[:id]

      @procedure = current_administrateur.procedures.find(id)

      Sentry.configure_scope do |scope|
        scope.set_tags(procedure: @procedure.id)
      end
    rescue ActiveRecord::RecordNotFound
      flash.alert = 'Démarche inexistante'
      redirect_to admin_procedures_path, status: 404
    end

    def reset_procedure
      @procedure.reset!
    end

    def ensure_not_super_admin!
      if administrateur_as_manager?
        redirect_back fallback_location: root_url, alert: "Interdit aux super admins", status: 403
      end
    end

    private

    def administrateur_as_manager?
      id = params[:procedure_id] || params[:id]

      current_administrateur.administrateurs_procedures
        .exists?(procedure_id: id, manager: true)
    end

    def alert_for_missing_siret_service
      procedures = missing_siret_services
      if procedures.any?
        errors = []
        errors << I18n.t('shared.procedures.no_siret')
        procedures.each do |p|
          errors << I18n.t('shared.procedures.add_siret_to_service_without_siret_html', link: edit_admin_service_path(p.service, procedure_id: p.id), nom: p.service.nom)
        end
        flash.now.alert = errors
      end
    end

    def missing_siret_services
      current_administrateur
        .procedures.publiees
        .joins(:service)
        .where(service: { siret: nil })
    end
  end
end
