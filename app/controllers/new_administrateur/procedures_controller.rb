module NewAdministrateur
  class ProceduresController < AdministrateurController
    before_action :retrieve_procedure, only: [:champs, :annotations, :edit, :monavis, :update_monavis, :jeton, :update_jeton]
    before_action :procedure_locked?, only: [:champs, :annotations]

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
      @terms_of_use_read = {}
    end

    def show
      @procedure = current_administrateur.procedures.find(params[:id])
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

      check_terms_of_use
      if !@procedure.errors.empty? || !@procedure.save
        flash.now.alert = @procedure.errors.full_messages
        render 'new'
      else
        flash.notice = 'Démarche enregistrée.'
        current_administrateur.instructeur.assign_to_procedure(@procedure)
        # FIXUP: needed during transition to revisions
        RevisionsMigration.add_revisions(@procedure)

        redirect_to champs_admin_procedure_path(@procedure)
      end
    end

    def update
      @procedure = current_administrateur.procedures.find(params[:id])

      check_terms_of_use
      if !@procedure.errors.empty? || !@procedure.update(procedure_params)
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
      if !@procedure.update(procedure_params)
        flash.now.alert = @procedure.errors.full_messages
      else
        flash.notice = 'Le jeton a bien été mis à jour'
      end
      render 'jeton'
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

    def check_terms_of_use
      terms_of_use = [:rgs_stamp, :rgpd]
      if terms_of_use.any? { |k| !params.key?(k) }
        @procedure.errors.add(:base, :rgpd_rgs_not_checked, message: 'Toutes les cases concernant le RGPD et le RGS doivent être cochées')
      end
      @terms_of_use_read = params.slice(*terms_of_use)
    end
  end
end
