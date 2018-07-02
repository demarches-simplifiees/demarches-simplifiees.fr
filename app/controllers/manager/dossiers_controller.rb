module Manager
  class DossiersController < Manager::ApplicationController
    def change_state_to_instruction
      dossier = Dossier.find(params[:id])
      dossier.update(state: 'en_instruction', processed_at: nil, motivation: nil)
      dossier.attestation&.destroy
      logger.info("Le dossier #{dossier.id} est repassé en instruction par #{current_administration.email}")
      flash[:notice] = "Le dossier #{dossier.id} est repassé en instruction"
      redirect_to manager_dossier_path(dossier)
    end
  end
end
