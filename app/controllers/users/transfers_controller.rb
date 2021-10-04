module Users
  class TransfersController < UserController
    def create
      transfer = DossierTransfer.new(transfer_params)
      transfer.save!
      redirect_to dossiers_path
    end

    def update
      DossierTransfer.accept(params[:id], current_user)
      redirect_to dossiers_path
    end

    def destroy
      transfer = DossierTransfer
        .joins(:dossiers)
        .find_by!(id: params[:id], dossiers: { user: current_user })

      transfer.destroy
      redirect_to dossiers_path
    end

    private

    def transfer_params
      transfer_params = params.require(:dossier_transfer).permit(:email, :dossiers)
      if transfer_params[:dossiers].present?
        transfer_params.merge(dossiers: [current_user.dossiers.find(transfer_params[:dossiers])])
      else
        transfer_params.merge(dossiers: current_user.dossiers)
      end
    end
  end
end
