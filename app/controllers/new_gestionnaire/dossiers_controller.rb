module NewGestionnaire
  class DossiersController < ProceduresController
    def attestation
      send_data(dossier.attestation.pdf.read, filename: 'attestation.pdf', type: 'application/pdf')
    end

    def show
      @dossier = dossier
    end

    def follow
      current_gestionnaire.follow(dossier)
      redirect_back(fallback_location: procedures_url)
    end

    def unfollow
      current_gestionnaire.followed_dossiers.delete(dossier)
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

    private

    def dossier
      current_gestionnaire.dossiers.find(params[:dossier_id])
    end
  end
end
