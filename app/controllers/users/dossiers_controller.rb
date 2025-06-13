# frozen_string_literal: true

module Users
  class DossiersController < UserController
    include DossierHelper
    include TurboChampsConcern
    include LockableConcern

    layout 'procedure_context', only: [:identite, :update_identite, :siret, :update_siret]

    ACTIONS_ALLOWED_TO_ANY_USER = [:index, :new,  :deleted_dossiers]
    ACTIONS_ALLOWED_TO_OWNER_OR_INVITE = [:show, :destroy, :demande, :messagerie, :brouillon, :modifier, :update, :create_commentaire, :papertrail, :restore, :champ]

    before_action :ensure_ownership!, except: ACTIONS_ALLOWED_TO_ANY_USER + ACTIONS_ALLOWED_TO_OWNER_OR_INVITE
    before_action :ensure_ownership_or_invitation!, only: ACTIONS_ALLOWED_TO_OWNER_OR_INVITE
    before_action :ensure_dossier_can_be_updated, only: [:update_identite, :update_siret, :brouillon, :submit_brouillon, :submit_en_construction, :modifier, :update, :champ]
    before_action :ensure_dossier_can_be_filled, only: [:brouillon, :modifier, :submit_brouillon, :submit_en_construction, :update]
    before_action :ensure_dossier_can_be_viewed, only: [:show]
    before_action :ensure_editing_brouillon, only: [:brouillon]
    before_action :forbid_closed_submission!, only: [:submit_brouillon]
    before_action :ensure_dossier_has_changes, only: [:submit_en_construction], if: :update_with_stream?
    before_action :set_dossier_as_editing_fork, only: [:submit_en_construction], if: :update_with_fork?
    before_action :set_dossier_stream, only: [:modifier, :update, :submit_en_construction, :champ], if: :update_with_stream?
    before_action :show_demarche_en_test_banner
    before_action :store_user_location!, only: :new

    around_action only: :submit_en_construction do |_controller, action|
      lock_action("lock-submit-en-construction-#{@dossier.id}", &action)
    end

    def index
      ordered_dossiers = Dossier.includes(:procedure).order_by_depose_at

      user_revisions = ProcedureRevision.where(dossiers: current_user.dossiers.visible_by_user)
      invite_revisions = ProcedureRevision.where(dossiers: current_user.dossiers_invites.visible_by_user)
      all_dossier_procedures = Procedure.where(revisions: user_revisions.or(invite_revisions))

      @procedures_for_select = all_dossier_procedures
        .distinct(:procedure_id)
        .order(:libelle)
        .pluck(:libelle, :id)

      @procedure_id = params[:procedure_id]
      if @procedure_id.present?
        ordered_dossiers = ordered_dossiers.where(procedures: { id: @procedure_id })
      end

      @search_terms = params[:q]
      if @search_terms.present?
        dossiers_filter_by_search = DossierSearchService.matching_dossiers_for_user(@search_terms, current_user).page
        ordered_dossiers = ordered_dossiers.merge(dossiers_filter_by_search)
      end

      @dossiers_visibles = ordered_dossiers.visible_by_user.preload(:etablissement, :individual, :invites)

      @user_dossiers = current_user.dossiers.state_not_termine.merge(@dossiers_visibles)
      @dossiers_traites = current_user.dossiers.state_termine.merge(@dossiers_visibles)
      @dossiers_invites = current_user.dossiers_invites.merge(@dossiers_visibles)
      @dossiers_supprimes = (current_user.dossiers.hidden_by_user.or(current_user.dossiers.hidden_by_expired)).merge(ordered_dossiers)
      @dossier_transferes = @dossiers_visibles.where(dossier_transfer_id: DossierTransfer.for_email(current_user.email))
      @dossiers_close_to_expiration = current_user.dossiers.close_to_expiration.merge(@dossiers_visibles)

      @statut = statut(@user_dossiers, @dossiers_traites, @dossiers_invites, @dossiers_supprimes, @dossier_transferes, @dossiers_close_to_expiration, params[:statut])

      @dossiers = case @statut
      when 'en-cours'
        @user_dossiers
      when 'traites'
        @dossiers_traites
      when 'dossiers-invites'
        @dossiers_invites
      when 'dossiers-supprimes'
        @dossiers_supprimes
      when 'dossiers-transferes'
        @dossier_transferes
      when 'dossiers-expirant'
        @dossiers_close_to_expiration
      end.page(page)

      @first_brouillon_recently_updated = current_user.dossiers.visible_by_user.brouillons_recently_updated.first

      @filter = DossiersFilter.new(current_user, params)
      @dossiers = @filter.filter_procedures(@dossiers).page(page)

      dossiers_ids = @dossiers.map(&:id)
      @rdvs_for_dossiers = Rdv.upcoming.where(dossier: dossiers_ids).group_by(&:dossier_id)
    end

    def show
      pj_service = PiecesJustificativesService.new(user_profile: current_user, export_template: nil)
      respond_to do |format|
        format.pdf do
          @dossier = dossier_with_champs(pj_template: false)
          @acls = pj_service.acl_for_dossier_export(@dossier.procedure)
          render(template: 'dossiers/show', formats: [:pdf])
        end
        format.all do
          @dossier = dossier
        end
      end
    end

    def demande
      @dossier = dossier_with_champs(pj_template: false)
    end

    def messagerie
      @dossier = dossier
      @commentaire = Commentaire.new
    end

    def rendez_vous
      @dossier = dossier
      @rdvs = @dossier.rdvs.booked.by_starts_at
    end

    def attestation
      if dossier.attestation&.pdf&.attached?
        redirect_to dossier.attestation.pdf.url, allow_other_host: true
      else
        flash.notice = t('.no_longer_available')
        redirect_to dossier_path(dossier)
      end
    end

    def papertrail
      raise ActionController::BadRequest if dossier.brouillon?
      @dossier = dossier
    end

    def set_accuse_lecture_agreement_at
      @dossier = dossier
      @dossier.update!(accuse_lecture_agreement_at: Time.zone.now)
      flash.notice = 'Accusé de lecture accepté'
      redirect_back(fallback_location: demande_dossier_path(@dossier))
    end

    def identite
      @dossier = dossier
      @user = current_user
      @no_description = true

      respond_to do |format|
        format.html
        format.turbo_stream do
          @dossier.for_tiers = params[:dossier][:for_tiers]
        end
      end
    end

    def update_identite
      @dossier = dossier
      @no_description = true
      email = dossier_params.dig('individual_attributes', 'email')

      if @dossier.update(dossier_params) && @dossier.individual.valid?
        # verify for_tiers email
        if email.present?
          User.create_or_promote_to_tiers(email, SecureRandom.hex, @dossier)
        end

        @dossier.update!(autorisation_donnees: true, identity_updated_at: Time.zone.now)
        DossierNotification.create_notification(dossier, :dossier_modifie)

        flash.notice = t('.identity_saved')

        if dossier.en_construction?
          redirect_to demande_dossier_path(@dossier)
        else
          redirect_to brouillon_dossier_path(@dossier)
        end
      else
        flash.now.alert = @dossier.individual.errors.full_messages + @dossier.errors.full_messages
        render :identite
      end
    end

    def siret
      @dossier = dossier
      @no_description = true
    end

    def update_siret
      @dossier = dossier
      @no_description = true

      # We use the user as the holder model object for the siret value
      # (so that we can restore it on the form in case of error).
      #
      # This is the only remaining use of User#siret: it could be refactored away.
      # However some existing users have a siret but no associated etablissement,
      # so we would need to analyze the legacy data and decide what to do with it.
      current_user.siret = siret_params[:siret]

      siret_model = Siret.new(siret: siret_params[:siret])
      if !siret_model.valid?
        return render_siret_error(siret_model.errors.full_messages)
      end

      sanitized_siret = siret_model.siret
      etablissement = begin
                        APIEntrepriseService.create_etablissement(@dossier, sanitized_siret, current_user.id)
                      rescue APIEntreprise::API::Error, APIEntrepriseToken::TokenError => error
                        if APIEntrepriseService.service_unavailable_error?(error, target: :insee)
                          # TODO: notify ops
                          APIEntrepriseService.create_etablissement_as_degraded_mode(@dossier, sanitized_siret, current_user.id)
                        else
                          Sentry.capture_exception(error, extra: { dossier_id: @dossier.id, siret: })

                          # probably random error, invite user to retry
                          return render_siret_error(t('errors.messages.siret.network_error'))
                        end
                      end

      if etablissement.nil?
        return render_siret_error(t('errors.messages.siret.not_found'))
      end

      current_user.update!(siret: sanitized_siret)
      @dossier.update!(autorisation_donnees: true)

      redirect_to etablissement_dossier_path
    end

    def etablissement
      @dossier = dossier

      # Redirect if the user attempts to access the page URL directly
      if !@dossier.etablissement
        flash.alert = t('.no_establishment')
        return redirect_to siret_dossier_path(@dossier)
      end
    end

    def brouillon
      session.delete(:prefill_token)
      session.delete(:prefill_params)
      @dossier = dossier_with_champs
      @dossier.validate(:champs_public_value)
    end

    def submit_brouillon
      @dossier = dossier_with_champs(pj_template: false)
      submit_dossier_and_compute_errors

      if @dossier.errors.blank? && @dossier.can_passer_en_construction?
        @dossier.passer_en_construction!
        DossierNotification.create_notification(@dossier, :dossier_depose)
        redirect_to merci_dossier_path(@dossier)
      else
        render :brouillon
      end
    end

    def extend_conservation
      dossier.extend_conservation(dossier.procedure.duree_conservation_dossiers_dans_ds.months)
      flash[:notice] = t('views.users.dossiers.archived_dossier', duree_conservation_dossiers_dans_ds: dossier.procedure.duree_conservation_dossiers_dans_ds)
      redirect_back(fallback_location: dossier_path(@dossier))
    end

    def extend_conservation_and_restore
      dossier.extend_conservation_and_restore(dossier.procedure.duree_conservation_dossiers_dans_ds.months, current_user)
      flash[:notice] = t('views.users.dossiers.archived_dossier', duree_conservation_dossiers_dans_ds: dossier.procedure.duree_conservation_dossiers_dans_ds)
      redirect_back(fallback_location: dossier_path(@dossier))
    end

    def modifier
      @dossier = dossier_with_champs

      if update_with_stream?
        @dossier_for_editing = dossier
      else
        # TODO remove when all forks are gone
        @dossier_for_editing = dossier.owner_editing_fork
        DossierPreloader.load_one(@dossier_for_editing)
      end
    end

    def submit_en_construction
      @dossier = dossier_with_champs(pj_template: false)
      editing_fork_origin = dossier.editing_fork_origin
      dossier_en_construction = editing_fork_origin || dossier

      if cast_bool(params.dig(:dossier, :pending_correction))
        dossier_en_construction.resolve_pending_correction
      end

      submit_dossier_and_compute_errors

      if dossier.errors.blank? && dossier.can_passer_en_construction?
        if editing_fork_origin.present?
          # TODO remove when all forks are gone
          editing_fork_origin.merge_fork(dossier)
          # merge_fork do a `reload`, the preloader is used to reload the whole tree
          DossierPreloader.load_one(editing_fork_origin)
        else
          dossier.merge_user_buffer_stream!
        end

        dossier_en_construction.submit_en_construction!

        DossierNotification.create_notification(dossier_en_construction, :dossier_modifie)

        redirect_to dossier_path(dossier_en_construction)
      else
        @dossier_for_editing = dossier
        if editing_fork_origin.present?
          @dossier = editing_fork_origin
        end

        render :modifier
      end
    end

    def update
      @dossier = update_with_fork? ? dossier.find_editing_fork(dossier.user) : dossier
      @dossier = dossier_with_champs(pj_template: false)
      update_dossier_and_compute_errors

      respond_to do |format|
        format.turbo_stream do
          @to_show, @to_hide, @to_update = champs_to_turbo_update(champs_public_attributes_params, dossier.project_champs_public_all)
          render :update, layout: false
        end
      end
    end

    def merci
      @dossier = current_user.dossiers.includes(:procedure).find(params[:id])
    end

    # polling url for champ
    def champ
      @dossier = dossier_with_champs(pj_template: false)
      type_de_champ = dossier.find_type_de_champ_by_stable_id(params[:stable_id], :public)
      champ = dossier.project_champ(type_de_champ, row_id: params[:row_id])

      champ.validate(:champs_public_value) if champ.external_data_fetched?
      respond_to do |format|
        format.turbo_stream do
          @to_show, @to_hide = []
          @to_update = [champ].concat(champ.prefillable_champs)
          render :update, layout: false
        end
      end
    end

    def create_commentaire
      @commentaire = CommentaireService.create(current_user, dossier, commentaire_params)

      if @commentaire.errors.empty?
        timestamps = [:last_commentaire_updated_at, :updated_at]
        timestamps << :last_commentaire_piece_jointe_updated_at if @commentaire.piece_jointe.attached?

        @commentaire.dossier.touch(*timestamps)

        DossierNotification.create_notification(dossier, :message_usager)

        flash.notice = t('.message_send')
        redirect_to messagerie_dossier_path(dossier)
      else
        flash.now.alert = @commentaire.errors.full_messages
        render :messagerie
      end
    end

    def destroy
      if dossier.can_be_deleted_by_user?
        if current_user.owns?(dossier)
          dossier.hide_and_keep_track!(current_user, :user_request)
        elsif current_user.invite?(dossier)
          current_user.invites.where(dossier:).destroy_all
        end
        flash.notice = t('users.dossiers.ask_deletion.soft_deleted_dossier')
        redirect_to dossiers_path
      else
        flash.alert = t('users.dossiers.ask_deletion.undergoingreview')
        redirect_to dossiers_path
      end
    end

    def new
      erase_user_location!

      begin
        procedure = if params[:brouillon]
          Procedure.publiees.or(Procedure.brouillons).find(params[:procedure_id])
        else
          Procedure.publiees.find(params[:procedure_id])
        end
      rescue ActiveRecord::RecordNotFound
        flash.alert = t('errors.messages.procedure_not_found')
        return redirect_to dossiers_path
      end

      dossier = Dossier.new(
        revision: params[:brouillon] ? procedure.draft_revision : procedure.active_revision,
        user: current_user,
        state: Dossier.states.fetch(:brouillon)
      )
      dossier.build_default_values
      dossier.save!
      DossierMailer.with(dossier:).notify_new_draft.deliver_later(wait: 1.hour)

      if dossier.procedure.for_individual
        redirect_to identite_dossier_path(dossier)
      else
        redirect_to siret_dossier_path(id: dossier.id)
      end
    end

    def dossier_for_help
      dossier_id = params[:id] || params[:dossier_id]
      @dossier || (dossier_id.present? && Dossier.visible_by_user.find_by(id: dossier_id.to_i))
    end

    def transferer
      @transfer = DossierTransfer.new(dossiers: [dossier])
    end

    def restore
      dossier.restore(current_user)
      flash.notice = t('users.dossiers.restore')
      redirect_to dossiers_path
    end

    def clone
      cloned_dossier = @dossier.clone
      DossierMailer.with(dossier: cloned_dossier).notify_new_draft.deliver_later
      flash.notice = t('users.dossiers.cloned_success')
      redirect_to brouillon_dossier_path(cloned_dossier)
    rescue ActiveRecord::RecordInvalid => e
      flash.alert = e.record.errors.full_messages
      redirect_to dossier_path(@dossier)
    end

    def deleted_dossiers
      @deleted_dossiers = current_user.deleted_dossiers.includes(:procedure).order_by_updated_at.page(page)
    end

    private

    # if the status tab is filled, then this tab
    # else first filled tab
    # else en-cours
    def statut(mes_dossiers, dossiers_traites, dossiers_invites, dossiers_supprimes, dossier_transferes, dossiers_close_to_expiration, params_statut)
      tabs = {
        'en-cours' => mes_dossiers,
        'traites' => dossiers_traites,
        'dossiers-invites' => dossiers_invites,
        'dossiers-supprimes' => dossiers_supprimes,
        'dossiers-transferes' => dossier_transferes,
        'dossiers-expirant' => dossiers_close_to_expiration
      }

      if tabs[params_statut]&.present?
        params_statut
      else
        tab = tabs.find { |_tab, scope| scope.present? }
        tab&.first || 'en-cours'
      end
    end

    def store_user_location!
      store_location_for(:user, request.fullpath)
    end

    def erase_user_location!
      clear_stored_location_for(:user)
    end

    def show_demarche_en_test_banner
      if @dossier.present? && @dossier.revision.draft?
        flash.now.alert = t('users.dossiers.test_procedure')
      end
    end

    def ensure_dossier_can_be_updated
      if !dossier.can_be_updated_by_user?
        flash.alert = t('users.dossiers.no_longer_editable')
        redirect_to dossier_path(dossier)
      end
    end

    def ensure_dossier_can_be_filled
      if !dossier.autorisation_donnees
        if dossier.procedure.for_individual
          flash.alert = t('users.dossiers.fill_identity.individual')
          redirect_to identite_dossier_path(dossier)
        else
          flash.alert = t('users.dossiers.fill_identity.siret')
          redirect_to siret_dossier_path(dossier)
        end
      end
    end

    def ensure_dossier_can_be_viewed
      if dossier.brouillon?
        redirect_to brouillon_dossier_path(dossier)
      end
    end

    def ensure_editing_brouillon
      if !dossier.brouillon?
        redirect_to modifier_dossier_path(@dossier)
      end
    end

    def page
      [params[:page].to_i, 1].max
    end

    def champs_public_params
      champ_attributes = [
        :id,
        :value,
        :value_other,
        :external_id,
        :code,
        :primary_value,
        :secondary_value,
        :numero_allocataire,
        :code_postal,
        :identifiant,
        :numero_fiscal,
        :reference_avis,
        :ine,
        :piece_justificative_file,
        :code_departement,
        :accreditation_number,
        :accreditation_birthdate,
        :address,
        :not_in_ban,
        :street_address,
        :city_name,
        :country_code,
        :commune_code,
        :postal_code,
        value: []
      ]
      # Strong attributes do not support records (indexed hash); they only support hashes with
      # static keys. We create a static hash based on the available keys.
      public_ids = params.dig(:dossier, :champs_public_attributes)&.keys || []
      champs_public_attributes = public_ids.map { [_1, champ_attributes] }.to_h
      params.require(:dossier).permit(champs_public_attributes:)
    end

    def champs_public_attributes_params
      champs_public_params.fetch(:champs_public_attributes)
    end

    def dossier_scope
      if action_name == 'update' || action_name == 'champ'
        Dossier.visible_by_user.or(Dossier.for_procedure_preview).or(Dossier.for_editing_fork)
      elsif action_name == 'restore'
        Dossier.hidden_by_user.or(Dossier.hidden_by_not_modified_for_a_long_time)
      elsif action_name == 'extend_conservation_and_restore' ||
            (action_name == 'show' && request.format.pdf?) ||
            action_name == 'attestation'
        Dossier.visible_by_user.or(Dossier.hidden_by_expired)
      else
        Dossier.visible_by_user
      end
    end

    def dossier
      @dossier ||= dossier_scope.find(params[:id] || params[:dossier_id]).tap do
        set_sentry_dossier(_1)
      end
    end

    def dossier_with_champs(pj_template: true)
      DossierPreloader.load_one(dossier, pj_template:)
    end

    def set_dossier_as_editing_fork
      @dossier = dossier.find_editing_fork(dossier.user)

      return if @dossier.present?

      flash[:alert] = t('users.dossiers.en_construction_submitted')
      redirect_to dossier_path(dossier)
    end

    def ensure_dossier_has_changes
      return if dossier.user_buffer_changes?

      flash[:alert] = t('users.dossiers.en_construction_submitted')
      redirect_to dossier_path(dossier)
    end

    def set_dossier_stream
      dossier.with_update_stream(current_user)
    end

    def update_with_stream?
      dossier.update_with_stream?
    end

    def update_with_fork?
      dossier.update_with_fork?
    end

    def update_dossier_and_compute_errors
      public_id, champ_attributes = champs_public_attributes_params.to_h.first
      champ = dossier.public_champ_for_update(public_id, updated_by: current_user.email)
      champ.assign_attributes(champ_attributes)
      champ_changed = champ.changed_for_autosave?

      # We save the dossier without validating fields, and if it is successful and the client
      # requests it, we ask for field validation errors.
      if Dossier.no_touching { champ.save }
        if dossier.brouillon? && champ_changed
          champ.update_timestamps
          if champ.used_by_routing_rules?
            @update_contact_information = true
            RoutingEngine.compute(dossier)
          end
        end

        if params[:validate].present? && !champ.fetch_external_data_pending?
          dossier.validate(:champs_public_value)
        end
      end
    end

    def submit_dossier_and_compute_errors
      dossier.validate(:champs_public_value)
      dossier.check_mandatory_and_visible_champs

      # TODO remove when all forks are gone
      if dossier.editing_fork_origin&.pending_correction?
        dossier.editing_fork_origin.validate(:champs_public_value)
        dossier.editing_fork_origin.errors.where(:pending_correction).each do |error|
          dossier.errors.import(error)
        end
      end
    end

    def ensure_ownership!
      if !current_user.owns?(dossier)
        forbidden!
      end
    end

    def ensure_ownership_or_invitation!
      if !current_user.owns_or_invite?(dossier)
        forbidden!
      end
    end

    def forbid_closed_submission!
      if !dossier.can_transition_to_en_construction?
        forbidden!
      end
    end

    def forbidden!
      flash[:alert] = t('users.dossiers.no_access_html', email: current_user.email)
      redirect_to root_path
    end

    def render_siret_error(error_message)
      flash.alert = error_message
      render :siret
    end

    def dossier_params
      params.require(:dossier).permit(:for_tiers, :mandataire_first_name, :mandataire_last_name, individual_attributes: [:gender, :nom, :prenom, :birthdate, :email, :notification_method])
    end

    def siret_params
      params.require(:user).permit(:siret)
    end

    def commentaire_params
      params.require(:commentaire).permit(:body, piece_jointe: [])
    end
  end
end
