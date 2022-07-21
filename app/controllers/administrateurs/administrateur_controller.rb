module Administrateurs
  class AdministrateurController < ApplicationController
    before_action :authenticate_administrateur!

    def retrieve_procedure
      id = params[:procedure_id] || params[:id]

      @procedure = current_administrateur.procedures.find(id)
    rescue ActiveRecord::RecordNotFound
      flash.alert = 'Démarche inexistante'
      redirect_to admin_procedures_path, status: 404
    end

    def retrieve_procedure_administration
      id = params[:procedure_id] || params[:id]

      @procedure_administration = current_administrateur.administrateurs_procedures.find_by(procedure_id: id)
    end

    def ensure_not_super_admin!
      procedure_administration = retrieve_procedure_administration
      if procedure_administration.manager?
        redirect_back fallback_location: root_url, alert: "Interdit aux super admins", status: 403
      end
    end

    def procedure_locked?
      if @procedure.locked?
        flash.alert = 'Démarche verrouillée'
        redirect_to admin_procedure_path(@procedure)
      end
    end

    def procedure_revisable?
      if @procedure.locked? && !@procedure.feature_enabled?(:procedure_revisions)
        flash.alert = 'Démarche verrouillée'
        redirect_to admin_procedure_path(@procedure)
      end
    end

    def reset_procedure
      if @procedure.brouillon? || @procedure.draft_changed?
        @procedure.reset!
      end
    end
  end
end
