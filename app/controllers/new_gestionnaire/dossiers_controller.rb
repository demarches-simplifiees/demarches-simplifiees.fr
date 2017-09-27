module NewGestionnaire
  class DossiersController < ProceduresController
    def attestation
      send_data(dossier.attestation.pdf.read, filename: 'attestation.pdf', type: 'application/pdf')
    end

    def show
      @dossier = dossier
      dossier.notifications.demande.mark_as_read
    end

    def messagerie
      @dossier = dossier
      dossier.notifications.messagerie.mark_as_read
    end

    def annotations_privees
      @dossier = dossier
    end

    def avis
      @dossier = dossier
      dossier.notifications.instruction.mark_as_read
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
      flash.notice = "Message envoyé"
      redirect_to messagerie_dossier_path(dossier.procedure, dossier)
    end

    def position
      etablissement = dossier.etablissement
      point = Carto::Geocodeur.convert_adresse_to_point(etablissement.geo_adresse) unless etablissement.nil?

      lon = "2.428462"
      lat = "46.538192"
      zoom = "13"

      unless point.nil?
        lon = point.x.to_s
        lat = point.y.to_s
      end

      render json: { lon: lon, lat: lat, zoom: zoom, dossier_id: params[:dossier_id] }
    end

    def create_avis
      Avis.create(avis_params.merge(claimant: current_gestionnaire, dossier: dossier))
      redirect_to avis_dossier_path(dossier.procedure, dossier)
    end

    def update_annotations
      dossier = current_gestionnaire.dossiers.includes(champs_private: :type_de_champ).find(params[:dossier_id])
      dossier.update_attributes(champs_private_params)
      redirect_to annotations_privees_dossier_path(dossier.procedure, dossier)
    end

    private

    def dossier
      current_gestionnaire.dossiers.find(params[:dossier_id])
    end

    def commentaire_params
      params.require(:commentaire).permit(:body)
    end

    def avis_params
      params.require(:avis).permit(:email, :introduction, :confidentiel)
    end

    def champs_private_params
      params.require(:dossier).permit(champs_private_attributes: [:id, :value, value: []])
    end
  end
end
