module NewAdministrateur
  class TypesDeChampController < AdministrateurController
    before_action :retrieve_procedure, only: [:create, :update, :destroy]
    before_action :procedure_locked?, only: [:create, :update, :destroy]

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

    def destroy
      type_de_champ = TypeDeChamp.where(procedure: @procedure).find(params[:id])

      type_de_champ.destroy
      reset_procedure

      head :no_content
    end

    private

    def serialize_type_de_champ(type_de_champ)
      {
        type_de_champ: type_de_champ.as_json(
          except: [:created_at, :updated_at, :stable_id, :type, :parent_id, :procedure_id, :private],
          methods: [:piece_justificative_template_filename, :piece_justificative_template_url, :drop_down_list_value]
        )
      }
    end

    def type_de_champ_create_params
      params.required(:type_de_champ).permit(:libelle,
        :description,
        :order_place,
        :type_champ,
        :private,
        :parent_id,
        :mandatory,
        :piece_justificative_template,
        :quartiers_prioritaires,
        :cadastres,
        :parcelles_agricoles,
        :drop_down_list_value).merge(procedure: @procedure)
    end

    def type_de_champ_update_params
      params.required(:type_de_champ).permit(:libelle,
        :description,
        :order_place,
        :type_champ,
        :mandatory,
        :piece_justificative_template,
        :quartiers_prioritaires,
        :cadastres,
        :parcelles_agricoles,
        :drop_down_list_value)
    end
  end
end
