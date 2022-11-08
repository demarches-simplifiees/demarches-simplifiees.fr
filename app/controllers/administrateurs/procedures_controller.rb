module Administrateurs
  class ProceduresController < AdministrateurController
    layout 'all', only: [:all, :administrateurs]

    before_action :retrieve_procedure, only: [:champs, :annotations, :modifications, :edit, :zones, :monavis, :update_monavis, :jeton, :update_jeton, :publication, :publish, :transfert, :close, :allow_expert_review, :experts_require_administrateur_invitation, :reset_draft]
    before_action :draft_valid?, only: [:apercu]

    ITEMS_PER_PAGE = 25

    def index
      @procedures_publiees = paginated_published_procedures
      @procedures_draft = paginated_draft_procedures
      @procedures_closed = paginated_closed_procedures
      @procedures_deleted = paginated_deleted_procedures
      @procedures_publiees_count = current_administrateur.procedures.publiees.count
      @procedures_draft_count = current_administrateur.procedures.brouillons.count
      @procedures_closed_count = current_administrateur.procedures.closes.count
      @procedures_deleted_count = current_administrateur.procedures.with_discarded.discarded.count
      @statut = params[:statut]
      @statut.blank? ? @statut = 'publiees' : @statut = params[:statut]
    end

    def paginated_published_procedures
      current_administrateur
        .procedures
        .publiees
        .page(params[:page])
        .per(ITEMS_PER_PAGE)
        .order(published_at: :desc)
    end

    def paginated_draft_procedures
      current_administrateur
        .procedures
        .brouillons
        .page(params[:page])
        .per(ITEMS_PER_PAGE)
        .order(created_at: :desc)
    end

    def paginated_closed_procedures
      current_administrateur
        .procedures
        .closes
        .page(params[:page])
        .per(ITEMS_PER_PAGE)
        .order(created_at: :desc)
    end

    def paginated_deleted_procedures
      current_administrateur
        .procedures
        .with_discarded
        .discarded
        .page(params[:page])
        .per(ITEMS_PER_PAGE)
        .order(created_at: :desc)
    end

    def apercu
      @dossier = procedure_without_control.draft_revision.dossier_for_preview(current_user)
      @tab = apercu_tab
    end

    def new
      @procedure ||= Procedure.new(for_individual: true)
      @existing_tags = Procedure.tags
    end

    SIGNIFICANT_DOSSIERS_THRESHOLD = 30

    def new_from_existing
      @grouped_procedures = nil
    end

    def search
      query = ActiveRecord::Base.sanitize_sql_like(params[:query])

      significant_procedure_ids = Procedure
        .publiees_ou_closes
        .where('unaccent(libelle) ILIKE unaccent(?)', "%#{query}%")
        .joins(:dossiers)
        .group("procedures.id")
        .having("count(dossiers.id) >= ?", SIGNIFICANT_DOSSIERS_THRESHOLD)
        .pluck('procedures.id')

      @grouped_procedures = Procedure
        .includes(:administrateurs, :service)
        .where(id: significant_procedure_ids)
        .group_by(&:organisation_name)
        .sort_by { |_, procedures| procedures.first.created_at }
    end

    def show
      @procedure = current_administrateur
        .procedures
        .includes(
          published_revision: :types_de_champ,
          draft_revision: :types_de_champ
        )
        .find(params[:id])

      @procedure.validate(:publication)

      @current_administrateur = current_administrateur
      @procedure_lien = commencer_url(path: @procedure.path)
      @procedure_lien_test = commencer_test_url(path: @procedure.path)
    end

    def edit
    end

    def zones
    end

    def create
      @procedure = Procedure.new(procedure_params.merge(administrateurs: [current_administrateur]))
      @procedure.draft_revision = @procedure.revisions.build

      if !@procedure.save
        flash.now.alert = @procedure.errors.full_messages
        render 'new'
      else
        flash.notice = 'Démarche enregistrée.'
        current_administrateur.instructeur.assign_to_procedure(@procedure)

        redirect_to champs_admin_procedure_path(@procedure)
      end
    end

    def update
      @procedure = current_administrateur.procedures.find(params[:id])

      if !@procedure.update(procedure_params)
        flash.now.alert = @procedure.errors.full_messages
        if @procedure.errors[:zones].present?
          render 'zones'
        else
          render 'edit'
        end
      elsif @procedure.brouillon?
        reset_procedure
        flash.notice = 'Démarche modifiée. Tous les dossiers de cette démarche ont été supprimés.'
        redirect_to admin_procedure_path(id: @procedure.id)
      else
        flash.notice = 'Démarche modifiée.'
        redirect_to admin_procedure_path(id: @procedure.id)
      end
    end

    def clone
      procedure = Procedure.find(params[:procedure_id])
      new_procedure = procedure.clone(current_administrateur, cloned_from_library?)

      if new_procedure.valid?
        flash.notice = 'Démarche clonée, pensez a vérifier la Présentation et choisir le service a laquelle cette procédure est associé.'
        redirect_to admin_procedure_path(id: new_procedure.id)
      else
        if cloned_from_library?
          flash.alert = new_procedure.errors.full_messages
          redirect_to new_from_existing_admin_procedures_path
        else
          flash.alert = new_procedure.errors.full_messages
          redirect_to admin_procedures_path
        end
      end

    rescue ActiveRecord::RecordNotFound
      flash.alert = 'Démarche inexistante'
      redirect_to admin_procedures_path
    end

    def archive
      procedure = current_administrateur.procedures.find(params[:procedure_id])

      if params[:new_procedure].present?
        new_procedure = current_administrateur.procedures.find(params[:new_procedure])
        procedure.update!(replaced_by_procedure_id: new_procedure.id)
      end

      procedure.close!

      flash.notice = "Démarche close"
      redirect_to admin_procedures_path

    rescue ActiveRecord::RecordNotFound
      flash.alert = 'Démarche inexistante'
      redirect_to admin_procedures_path
    end

    def destroy
      procedure = current_administrateur.procedures.find(params[:id])

      if procedure.can_be_deleted_by_administrateur?
        procedure.discard_and_keep_track!(current_administrateur)

        flash.notice = 'Démarche supprimée'
        redirect_to admin_procedures_draft_path
      else
        render json: {}, status: 403
      end
    end

    def restore
      procedure = current_administrateur.procedures.with_discarded.discarded.find(params[:id])
      procedure.restore_procedure(current_administrateur)
      flash.notice = t('administrateurs.index.restored', procedure_id: procedure.id)
      redirect_to admin_procedures_path
    end

    def monavis
    end

    def update_monavis
      if !@procedure.update(procedure_params)
        flash.now.alert = @procedure.errors.full_messages
      else
        flash.notice = 'le champ MonAvis a bien été mis à jour'
      end
      render 'monavis'
    end

    def jeton
    end

    def modifications
    end

    def update_jeton
      token = params[:procedure][:api_entreprise_token]
      @procedure.api_entreprise_token = token

      if @procedure.valid? &&
          APIEntreprise::PrivilegesAdapter.new(token).valid? &&
          @procedure.save

        redirect_to jeton_admin_procedure_path(procedure_id: params[:procedure_id]),
          notice: 'Le jeton a bien été mis à jour'
      else

        flash.now.alert = "Mise à jour impossible : le jeton n’est pas valide"
        render 'jeton'
      end
    end

    def publication
      @procedure = current_administrateur
        .procedures
        .includes(
          published_revision: :types_de_champ,
          draft_revision: :types_de_champ
        ).find(params[:procedure_id])

      @procedure_lien = commencer_url(path: @procedure.path)
      @procedure_lien_test = commencer_test_url(path: @procedure.path)
      @procedure.path = @procedure.suggested_path(current_administrateur)
      @current_administrateur = current_administrateur
      @closed_procedures = current_administrateur.procedures.with_discarded.closes.map { |p| ["#{p.libelle} (#{p.id})", p.id] }.to_h
    end

    def publish
      @procedure.assign_attributes(publish_params)

      if @procedure.draft_changed?
        if @procedure.close?
          if @procedure.publish_or_reopen!(current_administrateur)
            @procedure.publish_revision!
            flash.notice = "Démarche publiée"
          else
            flash.alert = @procedure.errors.full_messages
          end
        else
          @procedure.publish_revision!
          flash.notice = "Nouvelle version de la démarche publiée"
        end
      elsif @procedure.publish_or_reopen!(current_administrateur)
        flash.notice = "Démarche publiée"
      else
        flash.alert = @procedure.errors.full_messages
      end

      if params[:old_procedure].present? && @procedure.errors.empty?
        current_administrateur
          .procedures
          .with_discarded
          .closes
          .find(params[:old_procedure])
          .update!(replaced_by_procedure: @procedure)
      end

      redirect_to admin_procedure_path(@procedure)
    end

    def reset_draft
      @procedure.reset_draft_revision!
      redirect_to admin_procedure_path(@procedure)
    end

    def transfert
    end

    def close
    end

    def allow_expert_review
      @procedure.update!(allow_expert_review: !@procedure.allow_expert_review)
      flash.notice = @procedure.allow_expert_review? ? "Avis externes activés" : "Avis externes désactivés"
      redirect_to admin_procedure_experts_path(@procedure)
    end

    def transfer
      admin = Administrateur.by_email(params[:email_admin].downcase)
      if admin.nil?
        redirect_to admin_procedure_transfert_path(params[:procedure_id])
        flash.alert = "Envoi vers #{params[:email_admin]} impossible : cet administrateur n’existe pas"
      else
        procedure = current_administrateur.procedures.find(params[:procedure_id])
        procedure.clone(admin, false)
        redirect_to admin_procedure_path(params[:procedure_id])
        flash.notice = "La démarche a correctement été clonée vers le nouvel administrateur."
      end
    end

    def experts_require_administrateur_invitation
      @procedure.update!(experts_require_administrateur_invitation: !@procedure.experts_require_administrateur_invitation)
      flash.notice = @procedure.experts_require_administrateur_invitation? ? "Les experts sont gérés par les administrateurs de la démarche" : "Les experts sont gérés par les instructeurs"
      redirect_to admin_procedure_experts_path(@procedure)
    end

    def champs
      @procedure = Procedure.includes(draft_revision: { revision_types_de_champ_public: :type_de_champ }).find(@procedure.id)
    end

    def all
      @filter = ProceduresFilter.new(current_administrateur, params)
      @procedures = paginate(filter_procedures(@filter), published_at: :desc)
    end

    def administrateurs
      @filter = ProceduresFilter.new(current_administrateur, params)
      @admins = Administrateur.includes(:user, :procedures).where(id: AdministrateursProcedure.where(procedure: filter_procedures(@filter)).select(:administrateur_id))
      @admins = @admins.where('unaccent(users.email) ILIKE unaccent(?)', "%#{@filter.email}%") if @filter.email.present?
      @admins = paginate(@admins, 'users.email')
    end

    private

    def filter_procedures(filter)
      procedures_result = Procedure.joins(:procedures_zones).publiees_ou_closes
      procedures_result = procedures_result.where(procedures_zones: { zone_id: filter.zone_ids }) if filter.zone_ids.present?
      procedures_result = procedures_result.where(aasm_state: filter.statuses) if filter.statuses.present?
      procedures_result = procedures_result.where('published_at >= ?', filter.from_publication_date) if filter.from_publication_date.present?
      procedures_result = procedures_result.where('unaccent(libelle) ILIKE unaccent(?)', "%#{filter.libelle}%") if filter.libelle.present?
      procedures_result
    end

    def paginate(result, ordered_by)
      result.page(params[:page]).per(ITEMS_PER_PAGE).order(ordered_by)
    end

    def draft_valid?
      if procedure_without_control.draft_revision.invalid?
        flash.alert = t('preview_unavailable', scope: 'administrateurs.procedures')
        redirect_back(fallback_location: champs_admin_procedure_path(procedure_without_control))
      end
    end

    def apercu_tab
      params[:tab] || 'dossier'
    end

    def procedure_without_control
      Procedure.find(params[:id])
    end

    def procedure_params
      editable_params = [
        :libelle,
        :description,
        :organisation,
        :direction,
        :lien_site_web,
        :cadre_juridique,
        :deliberation,
        :notice,
        :web_hook_url,
        :declarative_with_state,
        :logo,
        :auto_archive_on,
        :monavis_embed,
        :api_entreprise_token,
        :duree_conservation_dossiers_dans_ds,
        { zone_ids: [] },
        :lien_dpo,
        :opendata,
        :procedure_expires_when_termine_enabled,
        :tags
      ]

      editable_params << :piece_justificative_multiple if @procedure&.piece_justificative_multiple == false

      permited_params = if @procedure&.locked?
        params.require(:procedure).permit(*editable_params)
      else
        params.require(:procedure).permit(*editable_params, :for_individual, :path)
      end
      if permited_params[:auto_archive_on].present?
        permited_params[:auto_archive_on] = Date.parse(permited_params[:auto_archive_on]) + 1.day
      end
      if permited_params[:tags].present?
        permited_params[:tags] = JSON.parse(permited_params[:tags])
      end
      permited_params
    end

    def publish_params
      params.permit(:path, :lien_site_web)
    end

    def allow_decision_access_params
      params.require(:experts_procedure).permit(:allow_decision_access)
    end

    def cloned_from_library?
      params[:from_new_from_existing].present?
    end
  end
end
