module NewAdministrateur
  class ProceduresController < AdministrateurController
    def apercu
      @dossier = procedure_without_control.new_dossier
    end

    private

    def procedure_without_control
      Procedure.find(params[:id])
    end
  end
end
