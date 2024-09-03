# frozen_string_literal: true

module Users
  class TransfersController < UserController
    def create
      transfer = DossierTransfer.new(transfer_params)

      if transfer.valid?
        transfer.save!
        flash.notice = t("users.dossiers.transferer.notice_sent")
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
      transfer = DossierTransfer.find(params[:id])
      authorized = (transfer.email == current_user.email || transfer.dossiers.exists?(dossiers: { user: current_user }))

      if authorized
        transfer.destroy_and_nullify
        flash.notice = t("users.dossiers.transferer.destroy")
      else
        flash.alert = t("users.dossiers.transferer.unauthorized_destroy")
      end
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
