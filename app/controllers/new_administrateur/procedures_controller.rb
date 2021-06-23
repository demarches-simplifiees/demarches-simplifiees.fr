module NewAdministrateur
  class ProceduresController < AdministrateurController
    before_action :retrieve_procedure, only: [:champs, :annotations, :edit, :monavis, :update_monavis, :jeton, :update_jeton, :publication, :publish, :transfert, :allow_expert_review, :experts_require_administrateur_invitation]
    before_action :procedure_revisable?, only: [:champs, :annotations]

    ITEMS_PER_PAGE = 25

    def index
      @procedures_publiees = paginated_published_procedures
      @procedures_draft = paginated_draft_procedures
      @procedures_closed = paginated_closed_procedures
      @procedures_publiees_count = current_administrateur.procedures.publiees.count
      @procedures_draft_count = current_administrateur.procedures.brouillons.count
      @procedures_closed_count = current_administrateur.procedures.closes.count
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

    def apercu
      @dossier = procedure_without_control.new_dossier
      @tab = apercu_tab
    end

    def new
      @procedure ||= Procedure.new(for_individual: true)
    end

    def show
      @procedure = current_administrateur.procedures.find(params[:id])
      @current_administrateur = current_administrateur
      if @procedure.brouillon?
        @procedure_lien = commencer_test_url(path: @procedure.path)
      else
        @procedure_lien = commencer_url(path: @procedure.path)
      end
    end

    def edit
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
        render 'edit'
      elsif @procedure.brouillon?
        reset_procedure
        flash.notice = 'Démarche modifiée. Tous les dossiers de cette démarche ont été supprimés.'
        redirect_to edit_admin_procedure_path(id: @procedure.id)
      else
        flash.notice = 'Démarche modifiée.'
        redirect_to edit_admin_procedure_path(id: @procedure.id)
      end
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
      if @procedure.brouillon?
        @procedure_lien = commencer_test_url(path: @procedure.path)
      else
        @procedure_lien = commencer_url(path: @procedure.path)
      end
      @procedure.path = @procedure.suggested_path(current_administrateur)
      @current_administrateur = current_administrateur
    end

    def publish
      @procedure.assign_attributes(publish_params)

      if @procedure.draft_changed?
        @procedure.publish_revision!
        flash.notice = "Nouvelle version de la démarche publiée"
        redirect_to admin_procedure_path(@procedure)
      elsif @procedure.publish_or_reopen!(current_administrateur)
        flash.notice = "Démarche publiée"
        redirect_to admin_procedure_path(@procedure)
      else
        flash.alert = @procedure.errors.full_messages
        redirect_to admin_procedure_path(@procedure)
      end
    end

    def transfert
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

    private

    def apercu_tab
      params[:tab] || 'dossier'
    end

    def procedure_without_control
      Procedure.find(params[:id])
    end

    def procedure_params
      editable_params = [:libelle, :description, :organisation, :direction, :lien_site_web, :cadre_juridique, :deliberation, :notice, :web_hook_url, :declarative_with_state, :euro_flag, :logo, :auto_archive_on, :monavis_embed, :api_entreprise_token]
      permited_params = if @procedure&.locked?
        params.require(:procedure).permit(*editable_params)
      else
        params.require(:procedure).permit(*editable_params, :duree_conservation_dossiers_dans_ds, :duree_conservation_dossiers_hors_ds, :for_individual, :path)
      end
      if permited_params[:auto_archive_on].present?
        permited_params[:auto_archive_on] = Date.parse(permited_params[:auto_archive_on]) + 1.day
      end
      permited_params
    end

    def publish_params
      params.permit(:path, :lien_site_web)
    end

    def allow_decision_access_params
      params.require(:experts_procedure).permit(:allow_decision_access)
    end
  end
end
