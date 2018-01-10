module Manager
  class ProceduresController < Manager::ApplicationController
    def whitelist
      procedure = Procedure.find(params[:id])
      procedure.whitelist!
      redirect_to manager_procedure_path(procedure)
    end
  end
end
