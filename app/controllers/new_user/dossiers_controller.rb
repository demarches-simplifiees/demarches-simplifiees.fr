module NewUser
  class DossiersController < UserController
    before_action :ensure_ownership!

    def attestation
      send_data(dossier.attestation.pdf.read, filename: 'attestation.pdf', type: 'application/pdf')
    end

    def identite
      @dossier = dossier
      @user = current_user
    end

    def update_identite
      @dossier = dossier

      individual_updated = @dossier.individual.update(individual_params)
      dossier_updated = @dossier.update(dossier_params)

      if individual_updated && dossier_updated
        flash.notice = "Identité enregistrée"

        if @dossier.procedure.module_api_carto.use_api_carto
          redirect_to users_dossier_carte_path(@dossier.id)
        else
          redirect_to identite_dossier_path(@dossier) # Simon should replace this with dossier_path when done
        end
      else
        flash.now.alert = @dossier.errors.full_messages
        render :identite
      end
    end

    private

    def dossier
      Dossier.find(params[:id] || params[:dossier_id])
    end

    def ensure_ownership!
      if dossier.user != current_user
        flash[:alert] = "Vous n'avez pas accès à ce dossier"
        redirect_to root_path
      end
    end

    def individual_params
      params.require(:individual).permit(:gender, :nom, :prenom, :birthdate)
    end

    def dossier_params
      params.require(:dossier).permit(:autorisation_donnees)
    end
  end
end
