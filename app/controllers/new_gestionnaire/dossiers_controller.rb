module NewGestionnaire
  class DossiersController < ProceduresController
    def attestation
      send_data(dossier.attestation.pdf.read, filename: 'attestation.pdf', type: 'application/pdf')
    end

    def show
      @dossier = dossier
    end

    def messagerie
      @dossier = dossier
    end

    def follow
      current_gestionnaire.follow(dossier)
      dossier.next_step!('gestionnaire', 'follow')
      flash.notice = 'Dossier suivi'
      redirect_back(fallback_location: procedures_url)
    end

    def unfollow
      current_gestionnaire.followed_dossiers.delete(dossier)
      flash.notice = "Vous ne suivez plus le dossier nº #{dossier.id}"

      redirect_back(fallback_location: procedures_url)
    end

    def archive
      dossier.update_attributes(archived: true)
      redirect_back(fallback_location: procedures_url)
    end

    def unarchive
      dossier.update_attributes(archived: false)
      redirect_back(fallback_location: procedures_url)
    end

    def create_commentaire
      Commentaire.create(commentaire_params.merge(email: current_gestionnaire.email, dossier: dossier))
      redirect_to messagerie_dossier_path(dossier.procedure, dossier)
    end

    private

    def dossier
      current_gestionnaire.dossiers.find(params[:dossier_id])
    end

    def commentaire_params
      params.require(:commentaire).permit(:body)
    end
  end
end
