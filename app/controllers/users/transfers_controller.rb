module Users
  class TransfersController < UserController
    def create
      transfer = DossierTransfer.new(transfer_params)

      if transfer.valid?
        transfer.save!
        redirect_to dossiers_path
      else
        flash.alert = transfer.errors.full_messages
        redirect_to transferer_dossier_path(transfer_params[:dossiers].first)
      end
    end

    def update
      DossierTransfer.accept(params[:id], current_user)
      redirect_to dossiers_path
    end

    def destroy
      transfer = DossierTransfer
        .joins(:dossiers)
        .find_by!(id: params[:id], dossiers: { user: current_user })

      transfer.destroy_and_nullify
      redirect_to dossiers_path
    end

    private

    def transfer_params
      transfer_params = params.require(:dossier_transfer).permit(:email, :dossier)

      dossier_id = transfer_params.delete(:dossier)
      dossiers = if dossier_id.present?
        [current_user.dossiers.find(dossier_id)]
      else
        current_user.dossiers
      end

      transfer_params.merge(dossiers: dossiers)
    end
  end
end
