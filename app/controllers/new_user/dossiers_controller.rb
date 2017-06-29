module NewUser
  class DossiersController < UserController
    before_action :ensure_ownership!

    def attestation
      send_data(dossier.attestation.pdf.read, filename: 'attestation.pdf', type: 'application/pdf')
    end

    private

    def dossier
      Dossier.find(params[:dossier_id])
    end

    def ensure_ownership!
      if dossier.user != current_user
        flash[:alert] = "Vous n'avez pas accès à ce dossier"
        redirect_to root_path
      end
    end
  end
end
