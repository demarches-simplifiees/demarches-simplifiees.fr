module Manager
  class DossiersController < Manager::ApplicationController
    #
    # Administrate overrides
    #

    # Override this if you have certain roles that require a subset
    # this will be used to set the records shown on the `index` action.
    def scoped_resource
      if unfiltered_list?
        # Don't display deleted dossiers in the unfiltered list…
        Dossier
      else
        # … but allow them to be searched and displayed.
        Dossier.unscope(:where)
      end
    end

    #
    # Custom actions
    #

    def hide
      dossier = Dossier.find(params[:id])
      dossier.hide!(current_administration)

      logger.info("Le dossier #{dossier.id} est supprimé par #{current_administration.email}")
      flash[:notice] = "Le dossier #{dossier.id} est supprimé"

      redirect_to manager_dossier_path(dossier)
    end

    private

    def unfiltered_list?
      action_name == "index" && !params[:search]
    end
  end
end
