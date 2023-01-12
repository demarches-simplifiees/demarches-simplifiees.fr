module Instructeurs
  class DossiersController < ProceduresController
    include ActionView::Helpers::NumberHelper
    include ActionView::Helpers::TextHelper
    include CreateAvisConcern
    include DossierHelper

    include ActionController::Streaming
    include Zipline

    before_action :redirect_on_dossier_not_found, only: :show
    before_action :redirect_on_dossier_in_batch_operation, only: [:archive, :unarchive, :follow, :unfollow, :passer_en_instruction, :repasser_en_construction, :repasser_en_instruction, :terminer, :restore, :destroy, :extend_conservation]
    after_action :mark_demande_as_read, only: :show

    after_action :mark_messagerie_as_read, only: [:messagerie, :create_commentaire]
    after_action :mark_avis_as_read, only: [:avis, :create_avis]
    after_action :mark_annotations_privees_as_read, only: [:annotations_privees, :update_annotations]

    def attestation
      if dossier.attestation.pdf.attached?
        redirect_to dossier.attestation.pdf.service_url
      end
    end

    def extend_conservation
      dossier.extend_conservation(1.month)
      flash[:notice] = t('views.instructeurs.dossiers.archived_dossier')
      redirect_back(fallback_location: instructeur_dossier_path(@dossier.procedure, @dossier))
    end

    def geo_data
      send_data dossier.to_feature_collection.to_json,
        type: 'application/json',
        filename: "dossier-#{dossier.id}-features.json"
    end

    def apercu_attestation
      @attestation = dossier.attestation_template.render_attributes_for(dossier: dossier)

      render 'administrateurs/attestation_templates/show', formats: [:pdf]
    end

    def bilans_bdf
      extension = params[:format]
      render extension.to_sym => dossier.etablissement.entreprise_bilans_bdf_to_sheet(extension)
    end

    def show
      @demande_seen_at = current_instructeur.follows.find_by(dossier: dossier_with_champs)&.demande_seen_at
      @is_dossier_in_batch_operation = dossier.batch_operation.present?

      respond_to do |format|
        format.pdf do
          @include_infos_administration = true
          render(template: 'dossiers/show', formats: [:pdf])
        end
        format.all
      end
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
      if @dossier.procedure.experts_require_administrateur_invitation?
        @experts_emails = dossier.procedure.experts_procedures.where(revoked_at: nil).map(&:expert).map(&:email).sort
      end
    end

    def personnes_impliquees
      @following_instructeurs_emails = dossier.followers_instructeurs.map(&:email)
      previous_followers = dossier.previous_followers_instructeurs - dossier.followers_instructeurs
      @previous_following_instructeurs_emails = previous_followers.map(&:email)
      @avis_emails = dossier.experts.map(&:email)
      @invites_emails = dossier.invites.map(&:email)
      @potential_recipients = dossier.groupe_instructeur.instructeurs.reject { |g| g == current_instructeur }
    end

    def send_to_instructeurs
      recipients = params['recipients'].presence || [].to_json
      recipients = Instructeur.find(JSON.parse(recipients))

      recipients.each do |recipient|
        recipient.follow(dossier)
        InstructeurMailer.send_dossier(current_instructeur, dossier, recipient).deliver_later
      end

      flash.notice = "Dossier envoyé"
      redirect_to(personnes_impliquees_instructeur_dossier_path(procedure, dossier))
    end

    def follow
      current_instructeur.follow(dossier)
      flash.notice = 'Dossier suivi'
      redirect_back(fallback_location: instructeur_procedure_path(procedure))
    end

    def unfollow
      current_instructeur.unfollow(dossier)
      flash.notice = "Vous ne suivez plus le dossier nº #{dossier.id}"

      redirect_back(fallback_location: instructeur_procedure_path(procedure))
    end

    def archive
      dossier.archiver!(current_instructeur)
      redirect_back(fallback_location: instructeur_procedure_path(procedure))
    end

    def unarchive
      dossier.desarchiver!
      redirect_back(fallback_location: instructeur_procedure_path(procedure))
    end

    def passer_en_instruction
      begin
        dossier.passer_en_instruction!(instructeur: current_instructeur)
        flash.notice = 'Dossier passé en instruction.'
      rescue AASM::InvalidTransition => e
        flash.alert = aasm_error_message(e, target_state: :en_instruction)
      end

      @dossier = dossier
      render :change_state
    end

    def repasser_en_construction
      begin
        dossier.repasser_en_construction!(instructeur: current_instructeur)
        flash.notice = 'Dossier repassé en construction.'
      rescue AASM::InvalidTransition => e
        flash.alert = aasm_error_message(e, target_state: :en_construction)
      end

      @dossier = dossier
      render :change_state
    end

    def repasser_en_instruction
      begin
        flash.notice = "Le dossier #{dossier.id} a été repassé en instruction."
        dossier.repasser_en_instruction!(instructeur: current_instructeur)
      rescue AASM::InvalidTransition => e
        flash.alert = aasm_error_message(e, target_state: :en_instruction)
      end

      @dossier = dossier
      render :change_state
    end

    def terminer
      motivation = params[:dossier] && params[:dossier][:motivation]
      justificatif = params[:dossier] && params[:dossier][:justificatif_motivation]

      h = { instructeur: current_instructeur, motivation: motivation, justificatif: justificatif }

      begin
        case params[:process_action]
        when "refuser"
          target_state = :refuse
          dossier.refuser!(h)
          flash.notice = "Dossier considéré comme refusé."
        when "classer_sans_suite"
          target_state = :sans_suite
          dossier.classer_sans_suite!(h)
          flash.notice = "Dossier considéré comme sans suite."
        when "accepter"
          target_state = :accepte
          dossier.accepter!(h)
          flash.notice = "Dossier traité avec succès."
        end
      rescue AASM::InvalidTransition => e
        flash.alert = aasm_error_message(e, target_state: target_state)
      end

      @dossier = dossier
      render :change_state
    end

    def create_commentaire
      @commentaire = CommentaireService.create(current_instructeur, dossier, commentaire_params)

      if @commentaire.errors.empty?
        @commentaire.dossier.update!(last_commentaire_updated_at: Time.zone.now)
        current_instructeur.follow(dossier)
        flash.notice = "Message envoyé"
        redirect_to messagerie_instructeur_dossier_path(procedure, dossier)
      else
        flash.alert = @commentaire.errors.full_messages
        render :messagerie
      end
    end

    def create_avis
      @avis = create_avis_from_params(dossier, current_instructeur)

      if @avis.nil?
        redirect_to avis_instructeur_dossier_path(procedure, dossier)
      else
        @avis_seen_at = current_instructeur.follows.find_by(dossier: dossier)&.avis_seen_at
        render :avis
      end
    end

    def update_annotations
      dossier_with_champs.assign_attributes(champs_private_params)
      if dossier.champs_private_all.any?(&:changed?)
        dossier.last_champ_private_updated_at = Time.zone.now
      end
      dossier.save
      dossier.log_modifier_annotations!(current_instructeur)

      respond_to do |format|
        format.html { redirect_to annotations_privees_instructeur_dossier_path(procedure, dossier) }
        format.turbo_stream
      end
    end

    def print
      @dossier = dossier
      render layout: "print"
    end

    def telecharger_pjs
      files = ActiveStorage::DownloadableFile.create_list_from_dossiers(Dossier.where(id: dossier.id), true)
      cleaned_files = ActiveStorage::DownloadableFile.cleanup_list_from_dossier(files)

      zipline(cleaned_files, "dossier-#{dossier.id}.zip")
    end

    def destroy
      if dossier.termine?
        dossier.hide_and_keep_track!(current_instructeur, :instructeur_request)
        flash.notice = t('instructeurs.dossiers.deleted_by_instructeur')
      else
        flash.alert = t('instructeurs.dossiers.impossible_deletion')
      end
      redirect_back(fallback_location: instructeur_procedure_path(procedure))
    end

    def restore
      dossier = current_instructeur.dossiers.find(params[:dossier_id])
      dossier.restore(current_instructeur)
      flash.notice = t('instructeurs.dossiers.restore')

      if dossier.termine?
        redirect_to instructeur_procedure_path(procedure, statut: :traites)
      else
        redirect_back(fallback_location: instructeur_procedure_path(procedure))
      end
    end

    private

    def dossier_scope
      if action_name == 'update_annotations'
        Dossier
          .where(id: current_instructeur.dossiers.visible_by_administration)
          .or(Dossier.where(id: current_user.dossiers.for_procedure_preview))
      else
        current_instructeur.dossiers.visible_by_administration
      end
    end

    def dossier
      @dossier ||= DossierPreloader.load_one(dossier_scope.find(params[:dossier_id]))
    end

    def dossier_with_champs
      @dossier ||= DossierPreloader.load_one(dossier_scope.find(params[:dossier_id]))
    end

    def commentaire_params
      params.require(:commentaire).permit(:body, :piece_jointe)
    end

    def champs_private_params
      champs_params = params.require(:dossier).permit(champs_private_attributes: [
        :id, :primary_value, :secondary_value, :piece_justificative_file, :value_other, :external_id, :numero_allocataire, :code_postal, :departement, :code_departement, :value, value: [],
        champs_attributes: [:id, :_destroy, :value, :primary_value, :secondary_value, :piece_justificative_file, :value_other, :external_id, :numero_allocataire, :code_postal, :departement, :code_departement, value: []]
      ])
      champs_params[:champs_private_all_attributes] = champs_params.delete(:champs_private_attributes) || {}
      champs_params
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

    def aasm_error_message(exception, target_state:)
      if exception.originating_state == target_state
        "Le dossier est déjà #{dossier_display_state(target_state, lower: true)}."
      elsif exception.failures.include?(:can_terminer?)
        "Les données relatives au SIRET de ce dossier n’ont pas pu encore être vérifiées : il n’est pas possible de le passer #{dossier_display_state(target_state, lower: true)}."
      else
        "Le dossier est en ce moment #{dossier_display_state(exception.originating_state, lower: true)} : il n’est pas possible de le passer #{dossier_display_state(target_state, lower: true)}."
      end
    end

    def redirect_on_dossier_not_found
      if !dossier_scope.exists?(id: params[:dossier_id])
        redirect_to instructeur_procedure_path(procedure)
      end
    end

    def redirect_on_dossier_in_batch_operation
      dossier_in_batch = begin
        dossier
                         rescue ActiveRecord::RecordNotFound
                           current_instructeur.dossiers.find(params[:dossier_id])
      end
      if dossier_in_batch.batch_operation.present?
        flash.alert = "Votre action n'a pas été effectuée, ce dossier fait parti d'un traitement de masse."
        redirect_back(fallback_location: instructeur_dossier_path(procedure, dossier_in_batch))
      end
    end
  end
end
