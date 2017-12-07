module NewGestionnaire
  class DossiersController < ProceduresController
    include ActionView::Helpers::NumberHelper
    include ActionView::Helpers::TextHelper

    after_action :mark_demande_as_read, only: :show
    after_action :mark_messagerie_as_read, only: [:messagerie, :create_commentaire]
    after_action :mark_avis_as_read, only: [:avis, :create_avis]

    def attestation
      send_data(dossier.attestation.pdf.read, filename: 'attestation.pdf', type: 'application/pdf')
    end

    def show
      @demande_seen_at = current_gestionnaire.follows.find_by(dossier: dossier)&.demande_seen_at
    end

    def messagerie
      @commentaire = Commentaire.new
      @messagerie_seen_at = current_gestionnaire.follows.find_by(dossier: dossier)&.messagerie_seen_at
    end

    def annotations_privees
      dossier.notifications.annotations_privees.mark_as_read
      current_gestionnaire.mark_tab_as_seen(dossier, :annotations_privees)
    end

    def avis
      @avis_seen_at = current_gestionnaire.follows.find_by(dossier: dossier)&.avis_seen_at
    end

    def personnes_impliquees
      @following_accompagnateurs_emails = dossier.followers_gestionnaires.pluck(:email)
      @avis_emails = dossier.avis.includes(:gestionnaire).map(&:email_to_display)
      @invites_emails = dossier.invites.map(&:email)
    end

    def follow
      current_gestionnaire.follow(dossier)
      dossier.next_step!('gestionnaire', 'follow')
      flash.notice = 'Dossier suivi'
      redirect_back(fallback_location: procedures_url)
    end

    def unfollow
      current_gestionnaire.unfollow(dossier)
      flash.notice = "Vous ne suivez plus le dossier nº #{dossier.id}"

      redirect_back(fallback_location: procedures_url)
    end

    def archive
      dossier.update_attributes(archived: true)
      current_gestionnaire.unfollow(dossier)
      redirect_back(fallback_location: procedures_url)
    end

    def unarchive
      dossier.update_attributes(archived: false)
      redirect_back(fallback_location: procedures_url)
    end

    def passer_en_instruction
      dossier.received!
      current_gestionnaire.follow(dossier)
      flash.notice = 'Dossier passé en instruction.'

      redirect_to dossier_path(procedure, dossier)
    end

    def repasser_en_construction
      dossier.initiated!
      flash.notice = 'Dossier repassé en construction.'

      redirect_to dossier_path(procedure, dossier)
    end

    def terminer
      if params[:dossier] && params[:dossier][:motivation].present?
        motivation = params[:dossier][:motivation]
      end

      case params[:process_action]
      when "refuser"
        next_step = "refuse"
        notice = "Dossier considéré comme refusé."
        template = procedure.refused_mail_template
      when "classer_sans_suite"
        next_step = "without_continuation"
        notice = "Dossier considéré comme sans suite."
        template = procedure.without_continuation_mail_template
      when "accepter"
        next_step = "close"
        notice = "Dossier traité avec succès."
        template = procedure.closed_mail_template
      end

      dossier.next_step!('gestionnaire', next_step, motivation)

      # needed to force Carrierwave to provide dossier.attestation.pdf.read
      # when the Feature.remote_storage is true, otherwise pdf.read is a closed stream.
      dossier.reload

      attestation_pdf = nil
      if check_attestation_emailable
        attestation_pdf = dossier.attestation.pdf.read
      end

      flash.notice = notice

      NotificationMailer.send_notification(dossier, template, attestation_pdf).deliver_now!

      redirect_to dossier_path(procedure, dossier)
    end

    def create_commentaire
      commentaire_hash = commentaire_params.merge(email: current_gestionnaire.email, dossier: dossier)

      # avoid simple_format replacing '' by '<p></p>'
      # and thus skipping the not empty constraint on commentaire's body
      if commentaire_hash[:body].present?
        commentaire_hash[:body] = simple_format(commentaire_hash[:body])
      end

      @commentaire = Commentaire.new(commentaire_hash)

      if @commentaire.save
        current_gestionnaire.follow(dossier)
        flash.notice = "Message envoyé"
        redirect_to messagerie_dossier_path(procedure, dossier)
      else
        flash.alert = @commentaire.errors.full_messages
        render :messagerie
      end
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
      redirect_to avis_dossier_path(procedure, dossier)
    end

    def update_annotations
      dossier = current_gestionnaire.dossiers.includes(champs_private: :type_de_champ).find(params[:dossier_id])
      dossier.update_attributes(champs_private_params)
      redirect_to annotations_privees_dossier_path(procedure, dossier)
    end

    def print
      @dossier = dossier
      render layout: "print"
    end

    private

    def dossier
      @dossier ||= current_gestionnaire.dossiers.find(params[:dossier_id])
    end

    def commentaire_params
      params.require(:commentaire).permit(:body, :file)
    end

    def avis_params
      params.require(:avis).permit(:email, :introduction, :confidentiel)
    end

    def champs_private_params
      params.require(:dossier).permit(champs_private_attributes: [:id, :value, value: []])
    end

    def check_attestation_emailable
      if dossier&.attestation&.emailable? == false
        human_size = number_to_human_size(dossier.attestation.pdf.size)
        msg = "the attestation of the dossier #{dossier.id} cannot be mailed because it is too heavy: #{human_size}"
        capture_message(msg, level: 'error')
      end

      dossier&.attestation&.emailable?
    end

    def mark_demande_as_read
      dossier.notifications.demande.mark_as_read
      current_gestionnaire.mark_tab_as_seen(dossier, :demande)
    end

    def mark_messagerie_as_read
      dossier.notifications.messagerie.mark_as_read
      current_gestionnaire.mark_tab_as_seen(dossier, :messagerie)
    end

    def mark_avis_as_read
      dossier.notifications.avis.mark_as_read
      current_gestionnaire.mark_tab_as_seen(dossier, :avis)
    end
  end
end
