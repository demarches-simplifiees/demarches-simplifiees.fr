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

    def change_state_to_instruction
      dossier = Dossier.find(params[:id])
      dossier.update(state: Dossier.states.fetch(:en_instruction), processed_at: nil, motivation: nil)
      dossier.attestation&.destroy
      logger.info("Le dossier #{dossier.id} est repassé en instruction par #{current_administration.email}")
      flash[:notice] = "Le dossier #{dossier.id} est repassé en instruction"
      DossierMailer.notify_revert_to_instruction(dossier).deliver_later
      redirect_to manager_dossier_path(dossier)
    end

    def hide
      dossier = Dossier.find(params[:id])
      deleted_dossier = dossier.hide!(current_administration)

      DossierMailer.notify_deletion_to_user(deleted_dossier, dossier.user.email).deliver_later
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
