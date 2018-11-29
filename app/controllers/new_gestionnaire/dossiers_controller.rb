module NewGestionnaire
  class DossiersController < ProceduresController
    include ActionView::Helpers::NumberHelper
    include ActionView::Helpers::TextHelper
    include CreateAvisConcern

    after_action :mark_demande_as_read, only: :show
    after_action :mark_messagerie_as_read, only: [:messagerie, :create_commentaire]
    after_action :mark_avis_as_read, only: [:avis, :create_avis]
    after_action :mark_annotations_privees_as_read, only: [:annotations_privees, :update_annotations]

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
      @annotations_privees_seen_at = current_gestionnaire.follows.find_by(dossier: dossier)&.annotations_privees_seen_at
    end

    def avis
      @avis_seen_at = current_gestionnaire.follows.find_by(dossier: dossier)&.avis_seen_at
      @avis = Avis.new
    end

    def personnes_impliquees
      @following_instructeurs_emails = dossier.followers_gestionnaires.pluck(:email)
      @avis_emails = dossier.avis.includes(:gestionnaire).map(&:email_to_display)
      @invites_emails = dossier.invites.map(&:email)
      @potential_recipients = procedure.gestionnaires.reject { |g| g == current_gestionnaire }
    end

    def send_to_instructeurs
      recipients = Gestionnaire.find(params[:recipients])

      recipients.each do |recipient|
        GestionnaireMailer.send_dossier(current_gestionnaire, dossier, recipient).deliver_later
      end

      flash.notice = "Dossier envoyé"
      redirect_to(personnes_impliquees_gestionnaire_dossier_path(procedure, dossier))
    end

    def follow
      current_gestionnaire.follow(dossier)
      flash.notice = 'Dossier suivi'
      redirect_back(fallback_location: gestionnaire_procedures_url)
    end

    def unfollow
      current_gestionnaire.unfollow(dossier)
      flash.notice = "Vous ne suivez plus le dossier nº #{dossier.id}"

      redirect_back(fallback_location: gestionnaire_procedures_url)
    end

    def archive
      dossier.update(archived: true)
      current_gestionnaire.unfollow(dossier)
      redirect_back(fallback_location: gestionnaire_procedures_url)
    end

    def unarchive
      dossier.update(archived: false)
      redirect_back(fallback_location: gestionnaire_procedures_url)
    end

    def passer_en_instruction
      dossier.passer_en_instruction!(current_gestionnaire)
      flash.notice = 'Dossier passé en instruction.'

      render partial: 'state_button_refresh', locals: { dossier: dossier }
    end

    def repasser_en_construction
      dossier.repasser_en_construction!(current_gestionnaire)
      flash.notice = 'Dossier repassé en construction.'

      render partial: 'state_button_refresh', locals: { dossier: dossier }
    end

    def terminer
      motivation = params[:dossier] && params[:dossier][:motivation]

      case params[:process_action]
      when "refuser"
        dossier.refuser!(current_gestionnaire, motivation)
        flash.notice = "Dossier considéré comme refusé."
      when "classer_sans_suite"
        dossier.classer_sans_suite!(current_gestionnaire, motivation)
        flash.notice = "Dossier considéré comme sans suite."
      when "accepter"
        dossier.accepter!(current_gestionnaire, motivation)
        flash.notice = "Dossier traité avec succès."
      end

      render partial: 'state_button_refresh', locals: { dossier: dossier }
    end

    def create_commentaire
      @commentaire = CommentaireService.build(current_gestionnaire, dossier, commentaire_params)

      if @commentaire.save
        current_gestionnaire.follow(dossier)
        flash.notice = "Message envoyé"
        redirect_to messagerie_gestionnaire_dossier_path(procedure, dossier)
      else
        flash.alert = @commentaire.errors.full_messages
        render :messagerie
      end
    end

    def create_avis
      @avis = create_avis_from_params(dossier)

      if @avis.nil?
        redirect_to avis_gestionnaire_dossier_path(procedure, dossier)
      else
        @avis_seen_at = current_gestionnaire.follows.find_by(dossier: dossier)&.avis_seen_at
        render :avis
      end
    end

    def update_annotations
      dossier = current_gestionnaire.dossiers.includes(champs_private: :type_de_champ).find(params[:dossier_id])
      # FIXME: add attachements validation, cf. Champ#piece_justificative_file_errors
      dossier.update(champs_private_params)
      redirect_to annotations_privees_gestionnaire_dossier_path(procedure, dossier)
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

    def champs_private_params
      params.require(:dossier).permit(champs_private_attributes: [
        :id, :primary_value, :secondary_value, :piece_justificative_file, :value, value: [],
        etablissement_attributes: Champs::SiretChamp::ETABLISSEMENT_ATTRIBUTES
      ])
    end

    def mark_demande_as_read
      current_gestionnaire.mark_tab_as_seen(dossier, :demande)
    end

    def mark_messagerie_as_read
      current_gestionnaire.mark_tab_as_seen(dossier, :messagerie)
    end

    def mark_avis_as_read
      current_gestionnaire.mark_tab_as_seen(dossier, :avis)
    end

    def mark_annotations_privees_as_read
      current_gestionnaire.mark_tab_as_seen(dossier, :annotations_privees)
    end
  end
end
