module Administrateurs
  class TypesDeChampController < AdministrateurController
    before_action :retrieve_procedure, only: [:create, :update, :move, :destroy]
    before_action :procedure_revisable?, only: [:create, :update, :move, :destroy]

    def create
      @type_de_champ = @procedure.draft_revision.add_type_de_champ(type_de_champ_create_params)

      if @type_de_champ.valid?
        reset_procedure
      else
        flash.alert = type_de_champ.errors.full_messages
      end
    end

    def update
      @type_de_champ = @procedure.draft_revision.find_or_clone_type_de_champ(params[:id])
      @should_update = !!params[:should_update]

      if @type_de_champ.update(type_de_champ_update_params)
        reset_procedure
      else
        flash.alert = @type_de_champ.errors.full_messages
      end
    end

    def move
      @type_de_champ = @procedure.draft_revision.move_type_de_champ(params[:id], params[:position].to_i)
    end

    def move_up
      @type_de_champ = @procedure.draft_revision.move_up_type_de_champ(params[:id])
    end

    def move_down
      @type_de_champ = @procedure.draft_revision.move_down_type_de_champ(params[:id])
    end

    def destroy
      @type_de_champ = @procedure.draft_revision.remove_type_de_champ(params[:id])
      reset_procedure
    end

    private

    def type_de_champ_create_params
      params
        .required(:type_de_champ)
        .permit(:type_champ, :parent_id, :private)
        .merge(libelle: 'Nouveau champ')
    end

    def type_de_champ_update_params
      params.required(:type_de_champ).permit(:type_champ,
        :libelle,
        :description,
        :mandatory,
        :drop_down_list_value,
        :drop_down_other,
        :drop_down_secondary_libelle,
        :drop_down_secondary_description,
        :piece_justificative_template,
        :contextual_help,
        :conditional_logic,
        :condition_source,
        :condition_operator,
        :condition_value,
        editable_options: [
          :cadastres,
          :unesco,
          :arretes_protection,
          :conservatoire_littoral,
          :reserves_chasse_faune_sauvage,
          :reserves_biologiques,
          :reserves_naturelles,
          :natura_2000,
          :zones_humides,
          :znieff
        ])
    end
  end
end
