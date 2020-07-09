module NewAdministrateur
  class ProceduresController < AdministrateurController
    before_action :retrieve_procedure, only: [:champs, :annotations, :edit, :monavis, :update_monavis, :jeton, :update_jeton]
    before_action :procedure_locked?, only: [:champs, :annotations]

    def apercu
      @dossier = procedure_without_control.new_dossier
      @tab = apercu_tab
    end

    def new
      @procedure ||= Procedure.new(for_individual: true)
    end

    def show
      @procedure = current_administrateur.procedures.find(params[:id])
    end

    def edit
    end

    def create
      @procedure = Procedure.new(procedure_params.merge(administrateurs: [current_administrateur]))

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
  end
end
