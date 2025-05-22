module Administrateurs
  class ProceduresController < AdministrateurController
    layout 'all', only: [:all, :administrateurs]
    respond_to :html, :xlsx

    before_action :retrieve_procedure, only: [:champs, :annotations, :modifications, :edit, :zones, :monavis, :update_monavis, :accuse_lecture, :update_accuse_lecture, :jeton, :update_jeton, :publication, :publish, :transfert, :close, :confirmation, :allow_expert_review, :allow_expert_messaging, :experts_require_administrateur_invitation, :reset_draft, :publish_revision, :check_path]
    before_action :draft_valid?, only: [:apercu]
    after_action :reset_procedure, only: [:update]

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
      DossierPreloader.load_one(@dossier)
      @tab = apercu_tab
      if @tab == 'dossier'
        @dossier.validate(:champs_public_value)
      else
        @dossier.validate(:champs_private_value)
      end
    end

    def new
      @procedure ||= Procedure.new(for_individual: true)
      @terms_of_use_read = {}
    end

    SIGNIFICANT_DOSSIERS_THRESHOLD = 30

    def new_from_existing
      @grouped_procedures = nil
    end

    def search
      query = ActiveRecord::Base.sanitize_sql_like(params[:query])

      significant_procedure_ids = Procedure
        .publiees_ou_closes
        .where(hidden_at_as_template: nil)
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
          published_revision: {
            types_de_champ: [],
            revision_types_de_champ: { type_de_champ: { piece_justificative_template_attachment: :blob } }
          },
          draft_revision: {
            types_de_champ: [],
            revision_types_de_champ: { type_de_champ: { piece_justificative_template_attachment: :blob } }
          },
          attestation_template_v1: [],
          attestation_templates_v2: [],
          initiated_mail: [],
          received_mail: [],
          closed_mail: [],
          refused_mail: [],
          without_continuation_mail: [],
          re_instructed_mail: []
        )
        .find(params[:id])

      @procedure.validate(:publication)
    end

    def edit
      @existing_tags = Procedure.tags
    end

    def zones
    end

    def create
      new_procedure_params = { max_duree_conservation_dossiers_dans_ds: Expired::DEFAULT_DOSSIER_RENTENTION_IN_MONTH }
        .merge(procedure_params)
        .merge(administrateurs: [current_administrateur])

      @procedure = Procedure.new(new_procedure_params)
      @procedure.draft_revision = @procedure.revisions.build

      check_terms_of_use
      if !@procedure.errors.empty? || !@procedure.save
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

      check_terms_of_use
      if !@procedure.errors.empty? || !@procedure.update(procedure_params)
        flash.now.alert = @procedure.errors.full_messages
        if @procedure.errors[:zones].present?
          render 'zones'
        else
          render 'edit'
        end
      elsif @procedure.brouillon?
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
        flash.notice = 'Démarche clonée. Pensez à vérifier la présentation et choisir le service à laquelle cette démarche est associée.'
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

      if procedure.update(closing_params)
        procedure.close!
        if (procedure.dossiers.not_archived.state_brouillon.present? || procedure.dossiers.not_archived.state_en_construction_ou_instruction.present?)
          redirect_to admin_procedure_closing_notification_path
        else
          flash.notice = "Démarche close"
          redirect_to admin_procedure_path(id: procedure.id)
        end
      else
        flash.alert = procedure.errors.full_messages
        redirect_to admin_procedure_close_path
      end

    rescue ActiveRecord::RecordNotFound
      flash.alert = 'Démarche inexistante'
      redirect_to admin_procedures_path
    end

    def closing_notification
      @procedure = current_administrateur.procedures.find(params[:procedure_id])
      @users_brouillon_count = @procedure.dossiers.not_archived.state_brouillon.count('distinct user_id')
      @users_en_cours_count = @procedure.dossiers.not_archived.state_en_construction_ou_instruction.count('distinct user_id')
    end

    def notify_after_closing
      @procedure = current_administrateur.procedures.find(params[:procedure_id])
      @procedure.update!(notification_closing_params)

      if (@procedure.closing_notification_brouillon? && params[:email_content_brouillon].blank?) || (@procedure.closing_notification_en_cours? && params[:email_content_en_cours].blank?)
        flash.alert = "Veuillez renseigner le contenu de l’email afin d’informer les usagers"
        redirect_to admin_procedure_closing_notification_path and return
      end

      if @procedure.closing_notification_brouillon?
        user_ids = @procedure.dossiers.not_archived.state_brouillon.pluck(:user_id).uniq
        content = params[:email_content_brouillon]
        SendClosingNotificationJob.perform_later(user_ids, content, @procedure)
        flash.notice = "Les emails sont en cours d'envoi"
      end

      if @procedure.closing_notification_en_cours?
        user_ids = @procedure.dossiers.not_archived.state_en_construction_ou_instruction.pluck(:user_id).uniq
        content = params[:email_content_en_cours]
        SendClosingNotificationJob.perform_later(user_ids, content, @procedure)
        flash.notice = "Les emails sont en cours d’envoi"
      end

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
      procedure.restore(current_administrateur)
      flash.notice = t('administrateurs.index.restored', procedure_id: procedure.id)
      redirect_to admin_procedures_path
    end

    def monavis
    end

    def update_monavis
      if !@procedure.update(procedure_params)
        flash.now.alert = @procedure.errors.full_messages
        render 'monavis'
      else
        flash.notice = 'le champ MonAvis a bien été mis à jour'
        redirect_to admin_procedure_path(id: @procedure.id)
      end
    end

    def accuse_lecture
    end

    def update_accuse_lecture
      @procedure.update!(procedure_params)
    end

    def jeton
    end

    def modifications
      ProcedureRevisionPreloader.new(@procedure.revisions).all
    end

    def update_jeton
      token = params[:procedure][:api_entreprise_token]
      @procedure.api_entreprise_token = token

      if @procedure.valid? &&
          APIEntreprise::PrivilegesAdapter.new(token).valid? &&
          @procedure.save

        flash.notice = 'Le jeton a bien été mis à jour'
        redirect_to admin_procedure_path(id: @procedure.id)
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

      if @procedure.auto_archive_on && !@procedure.auto_archive_on.future?
        flash.alert = "La date limite de dépôt des dossiers doit être postérieure à la date du jour pour réactiver la procédure. #{view_context.link_to('Veuillez la modifier', edit_admin_procedure_path(@procedure))}"
        redirect_to admin_procedure_path(@procedure)
      else
        @procedure.path = @procedure.suggested_path(current_administrateur)
        @current_administrateur = current_administrateur
        @closed_procedures = current_administrateur.procedures.with_discarded.closes.map { |p| ["#{p.libelle} (#{p.id})", p.id] }.to_h
      end
    end

    def check_path
      @path_available = @procedure.path_available?(params[:path])
      @other_procedure = @procedure.other_procedure_with_path(params[:path])
      respond_to do |format|
        format.turbo_stream do
          render :check_path
        end
      end
    end

    def publish
      @procedure.assign_attributes(publish_params)

      @procedure.publish_or_reopen!(current_administrateur)

      if @procedure.draft_changed?
        @procedure.publish_revision!
      end

      if params[:old_procedure].present? && @procedure.errors.empty?
        current_administrateur
          .procedures
          .with_discarded
          .closes
          .find(params[:old_procedure])
          .update!(replaced_by_procedure: @procedure)
      end

      # TO DO after data backfill add this condition before reset :
      # if @procedure.closing_reason.present?
      @procedure.reset_closing_params

      redirect_to admin_procedure_confirmation_path(@procedure)
    rescue ActiveRecord::RecordInvalid
      flash.alert = @procedure.errors.full_messages
      redirect_to admin_procedure_publication_path(@procedure)
    end

    def reset_draft
      @procedure.reset_draft_revision!
      flash.notice = 'Les modifications ont été annulées'
      redirect_to admin_procedure_path(@procedure)
    end

    def publish_revision
      @procedure.publish_revision!
      flash.notice = "Nouvelle version de la démarche publiée"

      redirect_to admin_procedure_path(@procedure)
    rescue ActiveRecord::RecordInvalid
      redirect_to admin_procedure_publication_path(@procedure)
    end

    def transfert
    end

    def close
      @published_procedures = current_administrateur.procedures.publiees.to_h { |p| ["#{p.libelle} (#{p.id})", p.id] }
      @closing_reason_options = Procedure.closing_reasons.values.map { |reason| [I18n.t("activerecord.attributes.procedure.closing_reasons.#{reason}", app_name: Current.application_name), reason] }
    end

    def confirmation
    end

    def allow_expert_review
      @procedure.update!(allow_expert_review: !@procedure.allow_expert_review)
      flash.notice = @procedure.allow_expert_review? ? "Avis externes activés" : "Avis externes désactivés"
      redirect_to admin_procedure_experts_path(@procedure)
    end

    def allow_expert_messaging
      @procedure.update!(allow_expert_messaging: !@procedure.allow_expert_messaging)
      flash.notice = @procedure.allow_expert_messaging ? "Les experts ont accès à la messagerie" : "Les experts n'ont plus accès à la messagerie"
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
      ProcedureRevisionPreloader.load_one(@procedure.draft_revision)
    end

    def annotations
      ProcedureRevisionPreloader.load_one(@procedure.draft_revision)
    end

    def detail
      @procedure = Procedure.find(params[:id])
      @show_detail = params[:show_detail]
      respond_to do |format|
        format.turbo_stream
      end
    end

    def all
      @filter = ProceduresFilter.new(current_administrateur, params)
      all_procedures = filter_procedures(@filter).map { |p| ProcedureDetail.new(p) }
      respond_to do |format|
        format.html do
          all_procedures = Kaminari.paginate_array(all_procedures.to_a, offset: 0, limit: ITEMS_PER_PAGE, total_count: all_procedures.count)
          @procedures = all_procedures.page(params[:page]).per(25)
        end
        format.xlsx do
          render xlsx: ProcedureDetail.to_xlsx(instances: all_procedures),
            filename: "demarches-#{@filter}"
        end
      end
    end

    def administrateurs
      @filter = ProceduresFilter.new(current_administrateur, params)
      pids = AdministrateursProcedure.select(:administrateur_id).where(procedure: filter_procedures(@filter).map { |p| p["id"] })
      @admins = Administrateur.includes(:user, :procedures).where(id: pids, procedures: { hidden_at_as_template: nil })
      @admins = @admins.where('unaccent(users.email) ILIKE unaccent(?)', "%#{@filter.email}%") if @filter.email.present?
      @admins = paginate(@admins, 'users.email')
    end

    private

    def filter_procedures(filter)
      if filter.service_siret.present?
        service = Service.find_by(siret: filter.service_siret)
        return Procedure.none if service.nil?
      end

      services = Service.where(departement: filter.service_departement) if filter.service_departement.present?

      procedures_result = Procedure.select(:id).left_joins(:procedures_zones).distinct.publiees_ou_closes
      procedures_result = procedures_result.where(procedures_zones: { zone_id: filter.zone_ids }) if filter.zone_ids.present?
      procedures_result = procedures_result.where(hidden_at_as_template: nil)
      procedures_result = procedures_result.where(aasm_state: filter.statuses) if filter.statuses.present?
      procedures_result = procedures_result.where("tags @> ARRAY[?]::text[]", filter.tags) if filter.tags.present?
      procedures_result = procedures_result.where(template: true) if filter.template?
      procedures_result = procedures_result.where(published_at: filter.from_publication_date..) if filter.from_publication_date.present?
      procedures_result = procedures_result.where(service: service) if filter.service_siret.present?
      procedures_result = procedures_result.where(service: services) if services
      procedures_result = procedures_result.where(for_individual: filter.for_individual) if filter.for_individual.present?
      procedures_result = procedures_result.where('unaccent(libelle) ILIKE unaccent(?)', "%#{filter.libelle}%") if filter.libelle.present?
      procedures_sql = procedures_result.to_sql

      sql = "select procedures.id, libelle, published_at, aasm_state, estimated_dossiers_count, template, array_agg(distinct latest_labels.name) filter (where latest_labels.name is not null) as latest_zone_labels from administrateurs_procedures inner join procedures on procedures.id = administrateurs_procedures.procedure_id left join procedures_zones ON procedures.id = procedures_zones.procedure_id left join zones ON zones.id = procedures_zones.zone_id left join (select zone_id, name from zone_labels where (zone_id, designated_on) in (select zone_id, max(designated_on) from zone_labels group by zone_id)) as latest_labels on zones.id = latest_labels.zone_id
      where procedures.id in (#{procedures_sql}) group by procedures.id order by published_at desc"
      ActiveRecord::Base.connection.execute(sql)
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
        :description_target_audience,
        :description_pj,
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
        :accuse_lecture,
        :api_entreprise_token,
        :duree_conservation_dossiers_dans_ds,
        :lien_dpo,
        :opendata,
        :procedure_expires_when_termine_enabled,
        { zone_ids: [], tags: [] }
      ]

      editable_params << :piece_justificative_multiple if @procedure && !@procedure.piece_justificative_multiple?

      permited_params = if @procedure&.locked?
        params.require(:procedure).permit(*editable_params)
      else
        params.require(:procedure).permit(*editable_params, :for_individual, :path)
      end
      if permited_params[:auto_archive_on].present?
        permited_params[:auto_archive_on] = Date.parse(permited_params[:auto_archive_on]) + 1.day
      end
      permited_params
    end

    def check_terms_of_use
      terms_of_use = [:rgs_stamp, :rgpd]
      if terms_of_use.any? { |k| params.key?(k) && params[k].to_i.zero? }
        @procedure.errors.add(:base, :rgpd_rgs_not_checked, message: 'Toutes les cases concernant le RGPD et le RGS doivent être cochées')
      end
      @terms_of_use_read = params.slice(*terms_of_use)
    end

    def publish_params
      params.permit(:path, :lien_site_web)
    end

    def closing_params
      closing_params = params.require(:procedure).permit(:closing_details, :closing_reason, :replaced_by_procedure_id)

      replaced_by_procedure_id = closing_params[:replaced_by_procedure_id]
      if replaced_by_procedure_id.present?
        if current_administrateur.procedures.find_by(id: replaced_by_procedure_id).blank?
          closing_params.delete(:replaced_by_procedure_id)
        end
      end
      closing_params
    end

    def notification_closing_params
      params.require(:procedure).permit(:closing_notification_brouillon, :closing_notification_en_cours)
    end

    def allow_decision_access_params
      params.require(:experts_procedure).permit(:allow_decision_access)
    end

    def cloned_from_library?
      params[:from_new_from_existing].present?
    end

    def update_lexpol(champ)
      return unless champ.lexpol?

      if champ.value.blank?
        champ.value = LexpolAPI.new.create_dossier(champ)
      else
        LexpolAPI.new.update_dossier(champ)
      end
      champ.save
    end
  end
end
