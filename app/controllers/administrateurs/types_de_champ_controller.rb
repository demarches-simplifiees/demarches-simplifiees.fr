module Administrateurs
  class TypesDeChampController < AdministrateurController
    before_action :retrieve_procedure, only: [:create, :update, :move, :estimate_fill_duration, :destroy]
    before_action :procedure_revisable?, only: [:create, :update, :move, :destroy]

    def create
      type_de_champ = @procedure.draft_revision.add_type_de_champ(type_de_champ_create_params)

      if type_de_champ.valid?
        reset_procedure
        render json: serialize_type_de_champ(type_de_champ), status: :created
      else
        render json: { errors: type_de_champ.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def update
      type_de_champ = @procedure.draft_revision.find_and_ensure_exclusive_use(params[:id])

      if type_de_champ.update(type_de_champ_update_params)
        reset_procedure
        render json: serialize_type_de_champ(type_de_champ)
      else
        render json: { errors: type_de_champ.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def move
      @procedure.draft_revision.move_type_de_champ(params[:id], params[:position].to_i)

      head :no_content
    end

    def estimate_fill_duration
      estimate = if @procedure.feature_enabled?(:procedure_estimated_fill_duration)
        @procedure.draft_revision.estimated_fill_duration
      else
        0
      end
      render json: { estimated_fill_duration: estimate }
    end

    def destroy
      @procedure.draft_revision.remove_type_de_champ(params[:id])
      reset_procedure

      head :no_content
    end

    private

    def serialize_type_de_champ(type_de_champ)
      { type_de_champ: type_de_champ.as_json_for_editor }
    end

    def type_de_champ_create_params
      params.required(:type_de_champ).permit(:type_champ,
        # polynesian
        :batiments,
        :level,
        :parcelles,
        :zones_manuelles,
        :min,
        :max,
        :accredited_user_string,
        # base
        :libelle,
        :description,
        :mandatory,
        :parent_id,
        :private,
        :drop_down_list_value,
        :drop_down_other,
        :drop_down_secondary_libelle,
        :drop_down_secondary_description,
        :piece_justificative_template,
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

    def type_de_champ_update_params
      params.required(:type_de_champ).permit(:type_champ,
        # polynesian
        :cadastres,
        :level,
        :parcelles,
        :batiments,
        :zones_manuelles,
        :min,
        :max,
        :accredited_user_string,
        # base
        :libelle,
        :description,
        :mandatory,
        :drop_down_list_value,
        :drop_down_other,
        :drop_down_secondary_libelle,
        :drop_down_secondary_description,
        :piece_justificative_template,
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
