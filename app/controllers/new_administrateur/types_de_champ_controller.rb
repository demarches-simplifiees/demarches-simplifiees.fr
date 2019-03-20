module NewAdministrateur
  class TypesDeChampController < AdministrateurController
    before_action :retrieve_procedure, only: [:create, :update, :move, :destroy]
    before_action :procedure_locked?, only: [:create, :update, :move, :destroy]

    def create
      type_de_champ = TypeDeChamp.new(type_de_champ_create_params)

      if type_de_champ.save
        reset_procedure
        render json: serialize_type_de_champ(type_de_champ), status: :created
      else
        render json: { errors: type_de_champ.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def update
      type_de_champ = TypeDeChamp.where(procedure: @procedure).find(params[:id])

      if type_de_champ.update(type_de_champ_update_params)
        reset_procedure
        render json: serialize_type_de_champ(type_de_champ)
      else
        render json: { errors: type_de_champ.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def move
      type_de_champ = TypeDeChamp.where(procedure: @procedure).find(params[:id])
      new_index = params[:order_place].to_i

      @procedure.move_type_de_champ(type_de_champ, new_index)

      head :no_content
    end

    def destroy
      type_de_champ = TypeDeChamp.where(procedure: @procedure).find(params[:id])

      type_de_champ.destroy!
      reset_procedure

      head :no_content
    end

    private

    def serialize_type_de_champ(type_de_champ)
      {
        type_de_champ: type_de_champ.as_json(
          except: [
            :created_at,
            :options,
            :order_place,
            :parent_id,
            :private,
            :procedure_id,
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
        )
      }
    end

    def type_de_champ_create_params
      params.required(:type_de_champ).permit(:cadastres,
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
        :type_champ).merge(procedure: @procedure)
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
