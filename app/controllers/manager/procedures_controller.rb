module Manager
  class ProceduresController < Manager::ApplicationController
    def whitelist
      procedure = Procedure.find(params[:id])
      procedure.whitelist!
      flash[:notice] = "Démarche whitelistée."
      redirect_to manager_procedure_path(procedure)
    end

    def draft
      procedure = Procedure.find(params[:id])
      if procedure.dossiers.empty?
        procedure.draft!
        flash[:notice] = "La démarche a bien été passée en brouillon."
      else
        flash[:alert] = "Impossible de repasser en brouillon une démarche à laquelle sont rattachés des dossiers."
      end
      redirect_to manager_procedure_path(procedure)
    end

    def hide
      procedure = Procedure.find(params[:id])
      procedure.hide!
      flash[:notice] = "La démarche a bien été supprimée, en cas d'erreur contactez un développeur."
      redirect_to manager_procedures_path
    end

    def add_administrateur
      procedure = Procedure.find(params[:id])
      administrateur = Administrateur.find_by(email: params[:email])
      if administrateur
        procedure.administrateurs << administrateur
        flash[:notice] = "L'administrateur \"#{params[:email]}\" est ajouté à la démarche."
      else
        flash[:alert] = "L'administrateur \"#{params[:email]}\" est introuvable."
      end
      redirect_to manager_procedure_path(procedure)
    end
  end
end
