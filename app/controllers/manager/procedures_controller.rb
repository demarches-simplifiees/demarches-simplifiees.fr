module Manager
  class ProceduresController < Manager::ApplicationController
    def whitelist
      procedure.whitelist!
      flash[:notice] = "Démarche whitelistée."
      redirect_to manager_procedure_path(procedure)
    end

    def draft
      if procedure.dossiers.empty?
        procedure.draft!
        flash[:notice] = "La démarche a bien été passée en brouillon."
      else
        flash[:alert] = "Impossible de repasser en brouillon une démarche à laquelle sont rattachés des dossiers."
      end
      redirect_to manager_procedure_path(procedure)
    end

    def hide
      procedure.hide!
      flash[:notice] = "La démarche a bien été supprimée, en cas d'erreur contactez un développeur."
      redirect_to manager_procedures_path
    end

    def add_administrateur
      administrateur = Administrateur.find_by(email: params[:email])
      if administrateur
        procedure.administrateurs << administrateur
        flash[:notice] = "L'administrateur \"#{params[:email]}\" est ajouté à la démarche."
      else
        flash[:alert] = "L'administrateur \"#{params[:email]}\" est introuvable."
      end
      redirect_to manager_procedure_path(procedure)
    end

    def change_piece_justificative_template
      if type_de_champ.update(type_de_champ_params)
        flash[:notice] = "Le modèle est mis à jour."
      else
        flash[:alert] = type_de_champ.errors.full_messages.join(', ')
      end
      redirect_to manager_procedure_path(procedure)
    end

    private

    def procedure
      Procedure.find(params[:id])
    end

    def type_de_champ
      TypeDeChamp.find(params[:type_de_champ][:id])
    end

    def type_de_champ_params
      params.require(:type_de_champ).permit(:piece_justificative_template)
    end
  end
end
