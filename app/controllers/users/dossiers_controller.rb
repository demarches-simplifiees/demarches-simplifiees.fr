module Users
  class DossiersController < UserController
    include DossierHelper
    include QueryParamsStoreConcern

    layout 'procedure_context', only: [:identite, :update_identite, :siret, :update_siret]

    ACTIONS_ALLOWED_TO_ANY_USER = [:index, :recherche, :new, :transferer_all]
    ACTIONS_ALLOWED_TO_OWNER_OR_INVITE = [:show, :demande, :messagerie, :brouillon, :update_brouillon, :submit_brouillon, :modifier, :update, :create_commentaire, :papertrail, :restore]

    before_action :ensure_ownership!, except: ACTIONS_ALLOWED_TO_ANY_USER + ACTIONS_ALLOWED_TO_OWNER_OR_INVITE
    before_action :ensure_ownership_or_invitation!, only: ACTIONS_ALLOWED_TO_OWNER_OR_INVITE
    before_action :ensure_dossier_can_be_updated, only: [:update_identite, :update_brouillon, :submit_brouillon, :modifier, :update]
    before_action :forbid_invite_submission!, only: [:submit_brouillon]
    before_action :forbid_closed_submission!, only: [:submit_brouillon]
    before_action :show_demarche_en_test_banner
    before_action :store_user_location!, only: :new

    def index
      dossiers = Dossier.includes(:procedure).order_by_updated_at.page(page)
      dossiers_visibles = dossiers.visible_by_user

      @user_dossiers = current_user.dossiers.state_not_termine.merge(dossiers_visibles)
      @dossiers_traites = current_user.dossiers.state_termine.merge(dossiers_visibles)
      @dossiers_close_to_expiration = current_user.dossiers.close_to_expiration.merge(dossiers_visibles)
      @dossiers_invites = current_user.dossiers_invites.merge(dossiers_visibles)
      @dossiers_supprimes_recemment = current_user.dossiers.hidden_by_user.merge(dossiers)
      @dossiers_supprimes_definitivement = current_user.deleted_dossiers.order_by_updated_at.page(page)
      @dossier_transfers = DossierTransfer.for_email(current_user.email).page(page)
      @statut = statut(@user_dossiers, @dossiers_traites, @dossiers_invites, @dossiers_supprimes_recemment, @dossiers_supprimes_definitivement, @dossier_transfers, @dossiers_close_to_expiration, params[:statut])
    end

    def show
      if dossier.brouillon?
        redirect_to brouillon_dossier_path(dossier)
        return
      end

      @dossier = dossier
      respond_to do |format|
        format.pdf do
          @include_infos_administration = false
          render(template: 'dossiers/show', formats: [:pdf])
        end
        format.all
      end
    end

    def demande
      @dossier = dossier
    end

    def messagerie
      @dossier = dossier
      @commentaire = Commentaire.new
    end

    def attestation
      if dossier.attestation&.pdf&.attached?
        redirect_to dossier.attestation.pdf.service_url
      else
        flash.notice = t('.no_longer_available')
        redirect_to dossier_path(dossier)
      end
    end

    def papertrail
      raise ActionController::BadRequest if dossier.brouillon?
      @dossier = dossier
    end

    def identite
      @dossier = dossier
      @user = current_user
    end

    def update_identite
      @dossier = dossier

      if @dossier.individual.update(individual_params)
        @dossier.update!(autorisation_donnees: true, identity_updated_at: Time.zone.now)
        flash.notice = t('.identity_saved')

        redirect_to brouillon_dossier_path(@dossier)
      else
        flash.now.alert = @dossier.individual.errors.full_messages
        render :identite
      end
    end

    def siret
      @dossier = dossier
    end

    def update_siret
      @dossier = dossier

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
                      rescue => error
                        if error.try(:network_error?) && !APIEntrepriseService.api_up?
                          # TODO: notify ops
                          APIEntrepriseService.create_etablissement_as_degraded_mode(@dossier, sanitized_siret, current_user.id)
                        else
                          Sentry.capture_exception(error, extra: { dossier_id: @dossier.id, siret: })

                          # probably random error, invite user to retry
                          return render_siret_error(t('errors.messages.siret_network_error'))
                        end
                      end

      if etablissement.nil?
        return render_siret_error(t('errors.messages.siret_unknown'))
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
      @dossier = dossier_with_champs
      @dossier.valid?(context: :prefilling)

      # TODO: remove when the champs are unifed
      if !@dossier.autorisation_donnees
        if dossier.procedure.for_individual
          redirect_to identite_dossier_path(@dossier)
        else
          redirect_to siret_dossier_path(@dossier)
        end
      end
    end

    def submit_brouillon
      @dossier = dossier_with_champs(pj_template: false)
      errors = submit_dossier_and_compute_errors

      if errors.blank?
        @dossier.passer_en_construction!
        @dossier.process_declarative!
        NotificationMailer.send_en_construction_notification(@dossier).deliver_later
        @dossier.groupe_instructeur.instructeurs.with_instant_email_dossier_notifications.each do |instructeur|
          DossierMailer.notify_new_dossier_depose_to_instructeur(@dossier, instructeur.email).deliver_later
        end

        redirect_to merci_dossier_path(@dossier)
      else
        flash.now.alert = errors

        respond_to do |format|
          format.html { render :brouillon }
          format.turbo_stream
        end
      end
    end

    def extend_conservation
      dossier.extend_conservation(dossier.procedure.duree_conservation_dossiers_dans_ds.months)
      flash[:notice] = t('views.users.dossiers.archived_dossier', duree_conservation_dossiers_dans_ds: dossier.procedure.duree_conservation_dossiers_dans_ds)
      redirect_back(fallback_location: dossier_path(@dossier))
    end

    def modifier
      @dossier = dossier_with_champs
    end

    def update_brouillon
      @dossier = dossier_with_champs
      update_dossier_and_compute_errors

      respond_to do |format|
        format.html { render :brouillon }
        format.turbo_stream do
          @to_show, @to_hide, @to_update = champs_to_turbo_update

          render(:update, layout: false)
        end
      end
    end

    def update
      @dossier = dossier_with_champs(pj_template: false)
      errors = update_dossier_and_compute_errors

      if errors.present?
        flash.now.alert = errors
      end

      respond_to do |format|
        format.html { render :modifier }
        format.turbo_stream do
          @to_show, @to_hide, @to_update = champs_to_turbo_update
        end
      end
    end

    def merci
      @dossier = current_user.dossiers.includes(:procedure).find(params[:id])
    end

    def create_commentaire
      @commentaire = CommentaireService.create(current_user, dossier, commentaire_params)

      if @commentaire.errors.empty?
        @commentaire.dossier.update!(last_commentaire_updated_at: Time.zone.now)
        dossier.followers_instructeurs
          .with_instant_email_message_notifications
          .each do |instructeur|
          DossierMailer.notify_new_commentaire_to_instructeur(dossier, instructeur.email).deliver_later
        end
        flash.notice = t('.message_send')
        redirect_to messagerie_dossier_path(dossier)
      else
        flash.now.alert = @commentaire.errors.full_messages
        render :messagerie
      end
    end

    def delete_dossier
      if dossier.can_be_deleted_by_user?
        dossier.hide_and_keep_track!(current_user, :user_request)
        flash.notice = t('users.dossiers.ask_deletion.soft_deleted_dossier')
        redirect_to dossiers_path
      else
        flash.alert = t('users.dossiers.ask_deletion.undergoingreview')
        redirect_to dossiers_path
      end
    end

    def recherche
      @search_terms = params[:q]
      return redirect_to dossiers_path if @search_terms.blank?

      @dossiers = DossierSearchService.matching_dossiers_for_user(@search_terms, current_user).page(page)

      if @dossiers.present?
        # we need the page condition when accessing page n with n>1 when the page has only 1 result
        # in order to avoid an unpleasant redirection when changing page
        if @dossiers.count == 1 && page == 1
          redirect_to url_for_dossier(@dossiers.first)
        else
          render :index
        end
      else
        flash.alert = "Vous n’avez pas de dossiers contenant « #{@search_terms} »."
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
        groupe_instructeur: procedure.defaut_groupe_instructeur_for_new_dossier,
        user: current_user,
        state: Dossier.states.fetch(:brouillon)
      )
      dossier.build_default_individual
      dossier.save!
      dossier.prefill!(PrefillParams.new(dossier, retrieve_and_delete_stored_query_params).to_a)
      DossierMailer.with(dossier:).notify_new_draft.deliver_later

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

    def transferer_all
      @transfer = DossierTransfer.new(dossiers: current_user.dossiers)
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

    private

    # if the status tab is filled, then this tab
    # else first filled tab
    # else en-cours
    def statut(mes_dossiers, dossiers_traites, dossiers_invites, dossiers_supprimes_recemment, dossiers_supprimes_definitivement, dossier_transfers, dossiers_close_to_expiration, params_statut)
      tabs = {
        'en-cours' => mes_dossiers.present?,
        'traites' => dossiers_traites.present?,
        'dossiers-invites' => dossiers_invites.present?,
        'dossiers-supprimes-recemment' => dossiers_supprimes_recemment.present?,
        'dossiers-supprimes-definitivement' => dossiers_supprimes_definitivement.present?,
        'dossiers-transferes' => dossier_transfers.present?,
        'dossiers-expirant' => dossiers_close_to_expiration.present?
      }
      if tabs[params_statut]
        params_statut
      else
        tabs
          .filter { |_tab, filled| filled }
          .map { |tab, _| tab }
          .first || 'en-cours'
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
        redirect_to dossiers_path
      end
    end

    def page
      [params[:page].to_i, 1].max
    end

    def champs_public_params
      champs_params = params.require(:dossier).permit(champs_public_attributes: [
        :id, :value, :value_other, :external_id, :primary_value, :secondary_value, :numero_allocataire, :code_postal, :identifiant, :numero_fiscal, :reference_avis, :ine, :piece_justificative_file, :departement, :code_departement, value: [],
        champs_attributes: [:id, :_destroy, :value, :value_other, :external_id, :primary_value, :secondary_value, :numero_allocataire, :code_postal, :identifiant, :numero_fiscal, :reference_avis, :ine, :piece_justificative_file, :departement, :code_departement, value: []]
      ])
      champs_params[:champs_public_all_attributes] = champs_params.delete(:champs_public_attributes) || {}
      champs_params
    end

    def dossier_scope
      if action_name == 'update_brouillon'
        Dossier.visible_by_user.or(Dossier.for_procedure_preview)
      elsif action_name == 'restore'
        Dossier.hidden_by_user
      else
        Dossier.visible_by_user
      end
    end

    def dossier
      @dossier ||= dossier_scope.find(params[:id] || params[:dossier_id]).tap do |dossier|
                       # Ease search & groupments by tags
                       Sentry.configure_scope do |scope|
                         scope.set_tags(procedure: dossier.procedure.id)
                         scope.set_tags(dossier: dossier.id)
                       end
                     end
    end

    def dossier_with_champs(pj_template: true)
      DossierPreloader.load_one(dossier, pj_template:)
    end

    def should_change_groupe_instructeur?
      if params[:dossier].key?(:groupe_instructeur_id)
        groupe_instructeur_id = params[:dossier][:groupe_instructeur_id]
        if groupe_instructeur_id.nil?
          @dossier.groupe_instructeur_id.present?
        else
          @dossier.groupe_instructeur_id != groupe_instructeur_id.to_i
        end
      end
    end

    def groupe_instructeur_from_params
      groupe_instructeur_id = params[:dossier][:groupe_instructeur_id]
      if groupe_instructeur_id.present?
        @dossier.procedure.groupe_instructeurs.find(groupe_instructeur_id)
      end
    end

    def should_fill_groupe_instructeur?
      !@dossier.procedure.routing_enabled? && @dossier.groupe_instructeur_id.nil?
    end

    def defaut_groupe_instructeur
      @dossier.procedure.defaut_groupe_instructeur
    end

    def update_dossier_and_compute_errors
      errors = []

      @dossier.assign_attributes(champs_public_params)
      if @dossier.champs_public_all.any?(&:changed_for_autosave?)
        @dossier.last_champ_updated_at = Time.zone.now
      end
      if !@dossier.save(**validation_options)
        errors += @dossier.errors.full_messages
      end

      if should_change_groupe_instructeur?
        @dossier.assign_to_groupe_instructeur(groupe_instructeur_from_params)
      end

      if dossier.en_construction?
        errors += @dossier.check_mandatory_and_visible_champs
      end

      errors
    end

    def submit_dossier_and_compute_errors
      errors = []

      @dossier.valid?(**submit_validation_options)
      errors += @dossier.errors.full_messages
      errors += @dossier.check_mandatory_and_visible_champs

      if should_fill_groupe_instructeur?
        @dossier.assign_to_groupe_instructeur(defaut_groupe_instructeur)
      end

      if @dossier.groupe_instructeur.nil?
        errors << "Le champ « #{@dossier.procedure.routing_criteria_name} » doit être rempli"
      end

      errors
    end

    def champs_to_turbo_update
      champ_ids = champs_public_params
        .fetch(:champs_public_all_attributes)
        .keys
        .map(&:to_i)

      to_update = dossier
        .champs_public_all
        .filter { _1.id.in?(champ_ids) && _1.refresh_after_update? }
      to_show, to_hide = dossier
        .champs_public_all
        .filter(&:conditional?)
        .partition(&:visible?)
        .map { champs_to_one_selector(_1 - to_update) }

      return to_show, to_hide, to_update
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

    def forbid_invite_submission!
      if !current_user.owns?(dossier)
        forbidden!
      end
    end

    def forbid_closed_submission!
      if !dossier.can_transition_to_en_construction?
        forbidden!
      end
    end

    def forbidden!
      flash[:alert] = t('users.dossiers.no_access')
      redirect_to root_path
    end

    def render_siret_error(error_message)
      flash.alert = error_message
      render :siret
    end

    def individual_params
      params.require(:individual).permit(:gender, :nom, :prenom, :birthdate)
    end

    def siret_params
      params.require(:user).permit(:siret)
    end

    def commentaire_params
      params.require(:commentaire).permit(:body, :piece_jointe)
    end

    def submit_validation_options
      # rubocop:disable Lint/BooleanSymbol
      # Force ActiveRecord to re-validate associated records.
      { context: :false }
      # rubocop:enable Lint/BooleanSymbol
    end

    def validation_options
      if dossier.brouillon?
        { context: :brouillon }
      else
        submit_validation_options
      end
    end

    def champs_to_one_selector(champs)
      champs
        .map(&:input_group_id)
        .map { |id| "##{id}" }
        .join(',')
    end
  end
end
