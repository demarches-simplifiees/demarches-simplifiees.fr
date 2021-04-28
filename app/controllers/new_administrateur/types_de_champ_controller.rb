module NewAdministrateur
  class TypesDeChampController < AdministrateurController
    before_action :retrieve_procedure, only: [:create, :update, :move, :destroy]
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
      type_de_champ = @procedure.draft_revision.find_or_clone_type_de_champ(params[:id])

      if type_de_champ.update(type_de_champ_update_params)
        reset_procedure
        render json: serialize_type_de_champ(type_de_champ)
      else
        render json: { errors: type_de_champ.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def move
      @procedure.draft_revision.move_type_de_champ(params[:id], (params[:position] || params[:order_place]).to_i)

      head :no_content
    end

    def destroy
      @procedure.draft_revision.remove_type_de_champ(params[:id])
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
            :revision_id,
            :stable_id,
            :type,
            :updated_at
          ],
          methods: [
            :drop_down_list_value,
            :piece_justificative_template_filename,
            :piece_justificative_template_url,
            :editable_options
          ]
        )
      }
    end

    def type_de_champ_create_params
      params.required(:type_de_champ).permit(:type_champ,
        :libelle,
        :description,
        :mandatory,
        :parent_id,
        :private,
        :drop_down_list_value,
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
        :libelle,
        :description,
        :mandatory,
        :drop_down_list_value,
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
