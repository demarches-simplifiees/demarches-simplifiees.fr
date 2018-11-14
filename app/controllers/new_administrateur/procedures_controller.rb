module NewAdministrateur
  class ProceduresController < AdministrateurController
    before_action :retrieve_procedure, only: [:update]
    before_action :procedure_locked?, only: [:update]

    TYPE_DE_CHAMP_ATTRIBUTES = [
      :_destroy,
      :libelle,
      :description,
      :order_place,
      :type_champ,
      :id,
      :mandatory,
      :piece_justificative_template,
      :quartiers_prioritaires,
      :cadastres,
      :parcelles_agricoles,
      drop_down_list_attributes: [:value]
    ]

    def apercu
      @dossier = procedure_without_control.new_dossier
      @tab = apercu_tab
    end

    def update
      if @procedure.update(procedure_params)
        flash.now.notice = 'Démarche enregistrée.'
        reset_procedure
      else
        flash.now.alert = @procedure.errors.full_messages
      end
    end

    private

    def apercu_tab
      params[:tab] || 'dossier'
    end

    def procedure_without_control
      Procedure.find(params[:id])
    end

    def procedure_params
      params.required(:procedure).permit(
        types_de_champ_attributes: TYPE_DE_CHAMP_ATTRIBUTES,
        types_de_champ_private_attributes: TYPE_DE_CHAMP_ATTRIBUTES
      )
    end
  end
end
