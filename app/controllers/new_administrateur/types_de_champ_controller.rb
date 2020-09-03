module NewAdministrateur
  class TypesDeChampController < AdministrateurController
    before_action :retrieve_procedure, only: [:create, :update, :move, :destroy]
    before_action :procedure_locked?, only: [:create, :update, :move, :destroy]

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
      type_de_champ = @procedure.draft_revision.find_or_clone_type_de_champ(TypeDeChamp.to_stable_id(params[:id]))

      if type_de_champ.update(type_de_champ_update_params)
        reset_procedure
        render json: serialize_type_de_champ(type_de_champ)
      else
        render json: { errors: type_de_champ.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def move
      @procedure.draft_revision.move_type_de_champ(TypeDeChamp.to_stable_id(params[:id]), (params[:position] || params[:order_place]).to_i)

      head :no_content
    end

    def destroy
      @procedure.draft_revision.remove_type_de_champ(TypeDeChamp.to_stable_id(params[:id]))
      reset_procedure

      head :no_content
    end

    private

    def serialize_type_de_champ(type_de_champ)
      {
        type_de_champ: type_de_champ.as_json(
          except: [
            :id,
            :created_at,
            :options,
            :order_place,
            :parent_id,
            :private,
            :procedure_id,
            :revision_id,
            :stable_id,
            :type,
            :updated_at
          ],
          methods: [
            :cadastres,
            :drop_down_list_value,
            :parcelles_agricoles,
            :piece_justificative_template_filename,
            :piece_justificative_template_url,
            :quartiers_prioritaires
          ]
        ).merge(id: TypeDeChamp.format_stable_id(type_de_champ.stable_id))
      }
    end

    def type_de_champ_create_params
      type_de_champ_params = params.required(:type_de_champ).permit(:cadastres,
        :description,
        :drop_down_list_value,
        :libelle,
        :mandatory,
        :order_place,
        :parcelles_agricoles,
        :parent_id,
        :piece_justificative_template,
        :private,
        :quartiers_prioritaires,
        :type_champ)

      if type_de_champ_params[:parent_id].present?
        type_de_champ_params[:parent_id] = TypeDeChamp.to_stable_id(type_de_champ_params[:parent_id])
      end

      type_de_champ_params
    end

    def type_de_champ_update_params
      params.required(:type_de_champ).permit(:cadastres,
        :description,
        :drop_down_list_value,
        :libelle,
        :mandatory,
        :parcelles_agricoles,
        :piece_justificative_template,
        :quartiers_prioritaires,
        :type_champ)
    end
  end
end
