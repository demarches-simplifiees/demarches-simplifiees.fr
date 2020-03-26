module Manager
  class ProceduresController < Manager::ApplicationController
    #
    # Administrate overrides
    #

    # Override this if you have certain roles that require a subset
    # this will be used to set the records shown on the `index` action.
    def scoped_resource
      if unfiltered_list?
        # Don't display discarded demarches in the unfiltered list…
        Procedure.kept
      else
        # … but allow them to be searched and displayed.
        Procedure.with_discarded
      end
    end

    def whitelist
      procedure.whitelist!
      flash[:notice] = "Démarche whitelistée."
      redirect_to manager_procedure_path(procedure)
    end

    def discard
      procedure.discard_and_keep_track!(current_administration)

      logger.info("La démarche #{procedure.id} est supprimée par #{current_administration.email}")
      flash[:notice] = "La démarche #{procedure.id} a été supprimée."

      redirect_to manager_procedure_path(procedure)
    end

    def add_administrateur
      administrateur = Administrateur.by_email(params[:email])
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
      @procedure ||= Procedure.with_discarded.find(params[:id])
    end

    def type_de_champ
      TypeDeChamp.find(params[:type_de_champ][:id])
    end

    def type_de_champ_params
      params.require(:type_de_champ).permit(:piece_justificative_template)
    end

    def unfiltered_list?
      action_name == "index" && !params[:search]
    end
  end
end
