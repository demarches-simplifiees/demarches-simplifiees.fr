module NewAdministrateur
  class AdministrateurController < ApplicationController
    before_action :authenticate_administrateur!

    def retrieve_procedure
      id = params[:procedure_id] || params[:id]

      @procedure = current_administrateur.procedures.find(id)

    rescue ActiveRecord::RecordNotFound
      flash.alert = 'Démarche inexistante'
      redirect_to admin_procedures_path
    end

    def procedure_locked?
      if @procedure.locked?
        flash.alert = 'Démarche verrouillée'
        redirect_to admin_procedure_path(@procedure)
      end
    end

    def reset_procedure
      if @procedure.brouillon_avec_lien?
        @procedure.reset!
      end
    end
  end
end
