module Users
  class DossiersController < UserController
    include DossierHelper
    include TurboChampsConcern

    layout 'procedure_context', only: [:identite, :update_identite, :siret, :update_siret]

    INSTANCE_ACTIONS_ALLOWED_TO_ANY_USER = [:qrcode]
    INSTANCE_ACIONS_ALLOWED_TO_OWNER_OR_INVITE = []

    ACTIONS_ALLOWED_TO_ANY_USER = [:index, :recherche, :new, :transferer_all] + INSTANCE_ACTIONS_ALLOWED_TO_ANY_USER
    ACTIONS_ALLOWED_TO_OWNER_OR_INVITE = [:show, :destroy, :demande, :messagerie, :brouillon, :submit_brouillon, :submit_en_construction, :modifier, :modifier_legacy, :update, :create_commentaire, :papertrail, :restore, :champ] + INSTANCE_ACIONS_ALLOWED_TO_OWNER_OR_INVITE

    before_action :ensure_ownership!, except: ACTIONS_ALLOWED_TO_ANY_USER + ACTIONS_ALLOWED_TO_OWNER_OR_INVITE
    before_action :ensure_ownership_or_invitation!, only: ACTIONS_ALLOWED_TO_OWNER_OR_INVITE
    before_action :ensure_dossier_can_be_updated, only: [:update_identite, :update_siret, :brouillon, :submit_brouillon, :submit_en_construction, :modifier, :modifier_legacy, :update, :champ]
    before_action :ensure_dossier_can_be_filled, only: [:brouillon, :modifier, :submit_brouillon, :submit_en_construction, :update]
    before_action :ensure_dossier_can_be_viewed, only: [:show]
    before_action :forbid_invite_submission!, only: [:submit_brouillon]
    before_action :forbid_closed_submission!, only: [:submit_brouillon]
    before_action :set_dossier_as_editing_fork, only: [:submit_en_construction]
    before_action :show_demarche_en_test_banner
    before_action :store_user_location!, only: :new

    def index
      dossiers = Dossier.includes(:procedure).order_by_updated_at
      dossiers_visibles = dossiers.visible_by_user

      @user_dossiers = current_user.dossiers.state_not_termine.merge(dossiers_visibles)
      @dossiers_traites = current_user.dossiers.state_termine.merge(dossiers_visibles)
      @dossiers_invites = current_user.dossiers_invites.merge(dossiers_visibles)
      @dossiers_supprimes_recemment = current_user.dossiers.hidden_by_user.merge(dossiers)
      @dossiers_supprimes_definitivement = current_user.deleted_dossiers.includes(:procedure).order_by_updated_at
      @dossier_transferes = dossiers_visibles.where(dossier_transfer_id: DossierTransfer.for_email(current_user.email).ids)
      @dossiers_close_to_expiration = current_user.dossiers.close_to_expiration.merge(dossiers_visibles)
      @statut = statut(@user_dossiers, @dossiers_traites, @dossiers_invites, @dossiers_supprimes_recemment, @dossiers_supprimes_definitivement, @dossier_transferes, @dossiers_close_to_expiration, params[:statut])

      @dossiers = case @statut
      when 'en-cours'
        @user_dossiers
      when 'traites'
        @dossiers_traites
      when 'dossiers-invites'
        @dossiers_invites
      when 'dossiers-supprimes-recemment'
        @dossiers_supprimes_recemment
      when 'dossiers-supprimes-definitivement'
        @dossiers_supprimes_definitivement
      when 'dossiers-transferes'
        @dossier_transferes
      when 'dossiers-expirant'
        @dossiers_close_to_expiration
      end.page(page)

      @first_brouillon_recently_updated = current_user.dossiers.visible_by_user.brouillons_recently_updated.first

      @filter = DossiersFilter.new(current_user, params)
      @dossiers = @filter.filter_procedures(@dossiers).page(page)
    end

    def show
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
        redirect_to dossier.attestation.pdf.url, allow_other_host: true
      else
        flash.notice = t('.no_longer_available')
        redirect_to dossier_path(dossier)
      end
    end

    def qrcode
      if dossier.match_encoded_date?(:created_at, params[:created_at])
        attestation_template = dossier.attestation_template
        if attestation_template&.activated
          @attestation = attestation_template.render_attributes_for(dossier: dossier)
          render 'qrcode'
        else
          attestation
        end
      else
        forbidden!
      end
    end

    def papertrail
      raise ActionController::BadRequest if dossier.brouillon?
      @dossier = dossier
    end

    def identite
      @dossier = dossier
      @user = current_user
      @no_description = true
    end

    def update_identite
      @dossier = dossier
      @no_description = true

      if @dossier.individual.update(individual_params)
        @dossier.update!(autorisation_donnees: true, identity_updated_at: Time.zone.now)
        flash.notice = t('.identity_saved')

        if dossier.en_construction?
          redirect_to demande_dossier_path(@dossier)
        else
          redirect_to brouillon_dossier_path(@dossier)
        end
      else
        flash.now.alert = @dossier.individual.errors.full_messages
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
      siret = siret_params[:siret]

      current_user.siret = siret

      siret_model = Siret.new(siret: siret)
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
      session.delete(:prefill_token)
      session.delete(:prefill_params)
      @dossier = dossier_with_champs
      @dossier.valid?(context: :prefilling)
    end

    def submit_brouillon
      @dossier = dossier_with_champs(pj_template: false)
      errors = submit_dossier_and_compute_errors

      if errors.blank?
        @dossier.passer_en_construction!
        @dossier.process_declarative!
        @dossier.process_sva_svr!
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

    # Transition to en_construction forks,
    # so users editing en_construction dossiers won't completely break their changes.
    # TODO: remove me after fork en_construction feature deploy (PR #8790)
    def modifier_legacy
      respond_to do |format|
        format.turbo_stream do
          flash.alert = "Une mise à jour de cette page est nécessaire pour poursuivre, veuillez la recharger (touche F5). Attention: le dernier champ modifié n’a pas été sauvegardé, vous devrez le ressaisir."
        end
      end
    end

    def submit_en_construction
      @dossier = dossier_with_champs(pj_template: false)
      errors = submit_dossier_and_compute_errors

      if errors.blank?
        editing_fork_origin = @dossier.editing_fork_origin
        editing_fork_origin.merge_fork(@dossier)
        RoutingEngine.compute(editing_fork_origin)

        if cast_bool(params.dig(:dossier, :pending_correction_confirm))
          editing_fork_origin.resolve_pending_correction!
          editing_fork_origin.process_sva_svr!
        end

        redirect_to dossier_path(editing_fork_origin)
      else
        flash.now.alert = errors

        respond_to do |format|
          format.html do
            @dossier = @dossier.editing_fork_origin
            render :modifier
          end

          format.turbo_stream do
            @to_show, @to_hide, @to_update = champs_to_turbo_update(champs_public_params.fetch(:champs_public_all_attributes), dossier.champs_public_all)
            render :update, layout: false
          end
        end
      end
    end

    def update
      @dossier = dossier.en_construction? ? dossier.find_editing_fork(dossier.user) : dossier
      @dossier = dossier_with_champs(pj_template: false)
      errors = update_dossier_and_compute_errors

      if errors.present?
        flash.now.alert = errors
      end

      respond_to do |format|
        format.turbo_stream do
          @to_show, @to_hide, @to_update = champs_to_turbo_update(champs_public_params.fetch(:champs_public_all_attributes), dossier.champs_public_all)
          render :update, layout: false
        end
      end
    end

    def merci
      @dossier = current_user.dossiers.includes(:procedure).find(params[:id])
    end

    def champ
      @dossier = dossier_with_champs(pj_template: false)
      champ = @dossier.champs_public_all.find(params[:champ_id])

      respond_to do |format|
        format.turbo_stream do
          @to_show, @to_hide = []
          @to_update = [champ]

          render :update, layout: false
        end
      end
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
    def statut(mes_dossiers, dossiers_traites, dossiers_invites, dossiers_supprimes_recemment, dossiers_supprimes_definitivement, dossier_transferes, dossiers_close_to_expiration, params_statut)
      tabs = {
        'en-cours' => mes_dossiers.present?,
        'traites' => dossiers_traites.present?,
        'dossiers-invites' => dossiers_invites.present?,
        'dossiers-supprimes-recemment' => dossiers_supprimes_recemment.present?,
        'dossiers-supprimes-definitivement' => dossiers_supprimes_definitivement.present?,
        'dossiers-transferes' => dossier_transferes.present?,
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

    def page
      [params[:page].to_i, 1].max
    end

    def champs_public_params
      champs_params = params.require(:dossier).permit(champs_public_attributes: [
        :id,
        :value,
        :value_other,
        :external_id,
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
        value: []
      ] + TypeDeChamp::INSTANCE_CHAMPS_PARAMS)
      champs_params[:champs_public_all_attributes] = champs_params.delete(:champs_public_attributes) || {}
      champs_params
    end

    def dossier_scope
      if action_name == 'update' || action_name == 'champ'
        Dossier.visible_by_user.or(Dossier.for_procedure_preview).or(Dossier.for_editing_fork)
      elsif action_name == 'restore'
        Dossier.hidden_by_user
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

    def update_dossier_and_compute_errors
      errors = []
      @dossier.assign_attributes(champs_public_params)
      if @dossier.champs_public_all.any?(&:changed_for_autosave?)
        @dossier.last_champ_updated_at = Time.zone.now
      end
      if !@dossier.save(**validation_options)
        errors += format_errors(errors: @dossier.errors)
      end

      errors
    end

    def submit_dossier_and_compute_errors
      errors = []

      @dossier.valid?(**submit_validation_options)
      errors += format_errors(errors: @dossier.errors)
      errors += format_errors(errors: @dossier.check_mandatory_and_visible_champs)

      RoutingEngine.compute(@dossier)

      errors
    end

    def format_errors(errors:)
      errors.map do |active_model_error|
        case active_model_error.class.name
        when "ActiveModel::NestedError"
          append_anchor_link(active_model_error.inner_error)
        when "ActiveModel::Error"
          append_anchor_link(active_model_error)
        else # "String"
          active_model_error
        end
      end
    end

    def append_anchor_link(error)
      model = error.base
      str_error = error.full_message
      return str_error if !model.is_a?(Champ)

      # attribute = error.attribute != :value ? ":" + error.attribute.to_s.gsub('_',' ') : nil
      route_helper = @dossier.editing_fork? ? :modifier_dossier_path : :brouillon_dossier_path
      [
        t('views.users.dossiers.label_champ', champ: model.libelle.truncate(200), message: str_error),
        helpers.link_to(t('views.users.dossiers.fix_champ'), public_send(route_helper, anchor: model.labelledby_id), class: 'error-anchor')
      ].join(", ")
    rescue # case of invalid type de champ on champ
      str_error
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
      params.require(:user).permit(:siret, :dossier_id)
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
  end
end
