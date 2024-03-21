module Manager
  class DossiersController < Manager::ApplicationController
    #
    # Administrate overrides
    #

    # Override this if you have certain roles that require a subset
    # this will be used to set the records shown on the `index` action.
    def scoped_resource
      if unfiltered_list?
        # Don't display discarded dossiers in the unfiltered list…
        Dossier.visible_by_administration
      else
        # … but allow them to be searched and displayed.
        Dossier
      end
    end

    def transfer_edit
      @dossier = Dossier.find params[:id]
    end

    def transfer
      transfer = DossierTransfer.create(email: params[:email], dossiers: [Dossier.find(params[:id])], from_support: true)
      if transfer.persisted?
        flash[:success] = "Une invitation de transfert a été envoyée à #{params[:email]}"
      else
        flash[:alert] = transfer.errors.full_messages.join("<br>")
      end

      redirect_to manager_dossier_path(params[:id])
    end

    def transfer_destroy
      dossier = Dossier.find(params[:id])
      dossier.transfer.destroy_and_nullify
      redirect_to manager_dossier_path(dossier), notice: t("users.dossiers.transferer.destroy")
    end

    private

    def unfiltered_list?
      action_name == "index" && !params[:search]
    end

    def paginate_resources(_resources)
      super.without_count
    end

    def find_resource(param)
      DossierPreloader.load_one(Dossier.find(param))
    end
  end
end
