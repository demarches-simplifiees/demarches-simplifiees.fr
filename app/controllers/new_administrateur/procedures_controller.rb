module NewAdministrateur
  class ProceduresController < AdministrateurController
    before_action :retrieve_procedure, only: [:champs, :annotations]
    before_action :procedure_locked?, only: [:champs, :annotations]

    def apercu
      @dossier = procedure_without_control.new_dossier
      @tab = apercu_tab
    end

    private

    def apercu_tab
      params[:tab] || 'dossier'
    end

    def procedure_without_control
      Procedure.find(params[:id])
    end
  end
end
