module Instructeurs
  class DossiersController < ProceduresController
    include ActionView::Helpers::NumberHelper
    include ActionView::Helpers::TextHelper
    include CreateAvisConcern
    include DossierHelper

    include ActionController::Streaming
    include Zipline

    after_action :mark_demande_as_read, only: :show
    after_action :mark_messagerie_as_read, only: [:messagerie, :create_commentaire]
    after_action :mark_avis_as_read, only: [:avis, :create_avis]
    after_action :mark_annotations_privees_as_read, only: [:annotations_privees, :update_annotations]

    def attestation
      if dossier.attestation.pdf_active_storage.attached?
        redirect_to url_for(dossier.attestation.pdf_active_storage)
      else
        send_data(dossier.attestation.pdf.read, filename: 'attestation.pdf', type: 'application/pdf')
      end
    end

    def apercu_attestation
      @title      = dossier.procedure.attestation_template.title
      @body       = dossier.procedure.attestation_template.body
      @footer     = dossier.procedure.attestation_template.footer
      @created_at = Time.zone.now
      @logo       = dossier.procedure.attestation_template&.proxy_logo
      @signature  = dossier.procedure.attestation_template&.proxy_signature

      render 'admin/attestation_templates/show', formats: [:pdf]
    end

    def show
      @demande_seen_at = current_instructeur.follows.find_by(dossier: dossier)&.demande_seen_at
    end

    def messagerie
      @commentaire = Commentaire.new
      @messagerie_seen_at = current_instructeur.follows.find_by(dossier: dossier)&.messagerie_seen_at
    end

    def annotations_privees
      @annotations_privees_seen_at = current_instructeur.follows.find_by(dossier: dossier)&.annotations_privees_seen_at
    end

    def avis
      @avis_seen_at = current_instructeur.follows.find_by(dossier: dossier)&.avis_seen_at
      @avis = Avis.new
    end

    def personnes_impliquees
      @following_instructeurs_emails = dossier.followers_instructeurs.pluck(:email)
      previous_followers = dossier.previous_followers_instructeurs - dossier.followers_instructeurs
      @previous_following_instructeurs_emails = previous_followers.pluck(:email)
      @avis_emails = dossier.avis.includes(:instructeur).map(&:email_to_display)
      @invites_emails = dossier.invites.map(&:email)
      @potential_recipients = procedure.instructeurs.reject { |g| g == current_instructeur }
    end

    def send_to_instructeurs
      recipients = Instructeur.find(params[:recipients])

      recipients.each do |recipient|
        InstructeurMailer.send_dossier(current_instructeur, dossier, recipient).deliver_later
      end

      flash.notice = "Dossier envoyé"
      redirect_to(personnes_impliquees_instructeur_dossier_path(procedure, dossier))
    end

    def follow
      current_instructeur.follow(dossier)
      flash.notice = 'Dossier suivi'
      redirect_back(fallback_location: instructeur_procedures_url)
    end

    def unfollow
      current_instructeur.unfollow(dossier)
      flash.notice = "Vous ne suivez plus le dossier nº #{dossier.id}"

      redirect_back(fallback_location: instructeur_procedures_url)
    end

    def archive
      dossier.update(archived: true)
      current_instructeur.unfollow(dossier)
      redirect_back(fallback_location: instructeur_procedures_url)
    end

    def unarchive
      dossier.update(archived: false)
      redirect_back(fallback_location: instructeur_procedures_url)
    end

    def passer_en_instruction
      if dossier.en_instruction?
        flash.notice = 'Le dossier est déjà en instruction.'
      else
        dossier.passer_en_instruction!(current_instructeur)
        flash.notice = 'Dossier passé en instruction.'
      end

      render partial: 'state_button_refresh', locals: { dossier: dossier }
    end

    def repasser_en_construction
      if dossier.en_construction?
        flash.notice = 'Le dossier est déjà en construction.'
      else
        dossier.repasser_en_construction!(current_instructeur)
        flash.notice = 'Dossier repassé en construction.'
      end

      render partial: 'state_button_refresh', locals: { dossier: dossier }
    end

    def repasser_en_instruction
      if dossier.en_instruction?
        flash.notice = 'Le dossier est déjà en instruction.'
      else
        if dossier.accepte?
          flash.notice = 'Il n’est pas possible de repasser un dossier accepté en instruction.'
        else
          flash.notice = "Le dossier #{dossier.id} a été repassé en instruction."
          dossier.repasser_en_instruction!(current_instructeur)
        end
      end

      render partial: 'state_button_refresh', locals: { dossier: dossier }
    end

    def terminer
      motivation = params[:dossier] && params[:dossier][:motivation]
      justificatif = params[:dossier] && params[:dossier][:justificatif_motivation]

      if dossier.termine?
        flash.notice = "Le dossier est déjà #{dossier_display_state(dossier, lower: true)}"
      else
        case params[:process_action]
        when "refuser"
          dossier.refuser!(current_instructeur, motivation, justificatif)
          flash.notice = "Dossier considéré comme refusé."
        when "classer_sans_suite"
          dossier.classer_sans_suite!(current_instructeur, motivation, justificatif)
          flash.notice = "Dossier considéré comme sans suite."
        when "accepter"
          dossier.accepter!(current_instructeur, motivation, justificatif)
          flash.notice = "Dossier traité avec succès."
        end
      end

      render partial: 'state_button_refresh', locals: { dossier: dossier }
    end

    def create_commentaire
      @commentaire = CommentaireService.build(current_instructeur, dossier, commentaire_params)

      if @commentaire.save
        current_instructeur.follow(dossier)
        flash.notice = "Message envoyé"
        redirect_to messagerie_instructeur_dossier_path(procedure, dossier)
      else
        flash.alert = @commentaire.errors.full_messages
        render :messagerie
      end
    end

    def create_avis
      @avis = create_avis_from_params(dossier)

      if @avis.nil?
        redirect_to avis_instructeur_dossier_path(procedure, dossier)
      else
        @avis_seen_at = current_instructeur.follows.find_by(dossier: dossier)&.avis_seen_at
        render :avis
      end
    end

    def update_annotations
      dossier = current_instructeur.dossiers.includes(champs_private: :type_de_champ).find(params[:dossier_id])
      dossier.update(champs_private_params)
      dossier.modifier_annotations!(current_instructeur)
      redirect_to annotations_privees_instructeur_dossier_path(procedure, dossier)
    end

    def print
      @dossier = dossier
      render layout: "print"
    end

    def telecharger_pjs
      return head(:forbidden) if !Flipflop.download_as_zip_enabled? || !dossier.attachments_downloadable?

      files = ActiveStorage::DownloadableFile.create_list_from_dossier(dossier)

      zipline(files, "dossier-#{dossier.id}.zip")
    end

    private

    def dossier
      @dossier ||= current_instructeur.dossiers.find(params[:dossier_id])
    end

    def commentaire_params
      params.require(:commentaire).permit(:body, :piece_jointe)
    end

    def champs_private_params
      params.require(:dossier).permit(champs_private_attributes: [
        :id, :primary_value, :secondary_value, :piece_justificative_file, :value, value: [],
        champs_attributes: [:id, :_destroy, :value, :primary_value, :secondary_value, :piece_justificative_file, value: []]
      ])
    end

    def mark_demande_as_read
      current_instructeur.mark_tab_as_seen(dossier, :demande)
    end

    def mark_messagerie_as_read
      current_instructeur.mark_tab_as_seen(dossier, :messagerie)
    end

    def mark_avis_as_read
      current_instructeur.mark_tab_as_seen(dossier, :avis)
    end

    def mark_annotations_privees_as_read
      current_instructeur.mark_tab_as_seen(dossier, :annotations_privees)
    end
  end
end
