module Administrateurs
  class TypesDeChampController < AdministrateurController
    before_action :retrieve_procedure, only: [:create, :update, :move, :move_up, :move_down, :destroy]
    before_action :procedure_revisable?, only: [:create, :update, :move, :move_up, :move_down, :destroy]

    def create
      type_de_champ = @procedure.draft_revision.add_type_de_champ(type_de_champ_create_params)

      if type_de_champ.valid?
        @coordinate = @procedure.draft_revision.coordinate_for(type_de_champ)
        reset_procedure
        flash.notice = "Formulaire enregistré"
      else
        flash.alert = type_de_champ.errors.full_messages
      end
    end

    def update
      type_de_champ = @procedure.draft_revision.find_and_ensure_exclusive_use(params[:id])

      if type_de_champ.update(type_de_champ_update_params)
        if params[:should_render]
          @coordinate = @procedure.draft_revision.coordinate_for(type_de_champ)
        end
        reset_procedure
        flash.notice = "Formulaire enregistré"
      else
        flash.alert = type_de_champ.errors.full_messages
      end
    end

    def move
      flash.notice = "Formulaire enregistré"
      @procedure.draft_revision.move_type_de_champ(params[:id], params[:position].to_i)
    end

    def move_up
      flash.notice = "Formulaire enregistré"
      @coordinate = @procedure.draft_revision.move_up_type_de_champ(params[:id])
    end

    def move_down
      flash.notice = "Formulaire enregistré"
      @coordinate = @procedure.draft_revision.move_down_type_de_champ(params[:id])
    end

    def destroy
      @coordinate = @procedure.draft_revision.remove_type_de_champ(params[:id])
      reset_procedure
      flash.notice = "Formulaire enregistré"
    end

    private

    def type_de_champ_create_params
      params
        .required(:type_de_champ)
        .permit(:type_champ, :parent_id, :private, :libelle, :after_id)
    end

    INSTANCE_EDITABLE_OPTIONS = TypesDeChamp::TeFenuaTypeDeChamp::LAYERS

    def type_de_champ_update_params
      params.required(:type_de_champ).permit(:type_champ,
        *TypeDeChamp::INSTANCE_OPTIONS,
        :libelle,
        :description,
        :mandatory,
        :drop_down_list_value,
        :drop_down_other,
        :drop_down_secondary_libelle,
        :drop_down_secondary_description,
        :piece_justificative_template,
        editable_options: [
          *INSTANCE_EDITABLE_OPTIONS,
          *TypesDeChamp::CarteTypeDeChamp::LAYERS
        ])
    end
  end
end
