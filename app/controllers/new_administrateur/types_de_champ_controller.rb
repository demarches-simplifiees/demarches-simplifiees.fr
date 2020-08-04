module NewAdministrateur
  class TypesDeChampController < AdministrateurController
    before_action :retrieve_procedure, only: [:create, :update, :move, :destroy]
    before_action :procedure_locked?, only: [:create, :update, :move, :destroy]
    before_action :revisions_migration

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
      type_de_champ = @procedure.draft_revision.find_or_clone_type_de_champ(type_de_champ_stable_id)

      if type_de_champ.update(type_de_champ_update_params)
        reset_procedure
        render json: serialize_type_de_champ(type_de_champ)
      else
        render json: { errors: type_de_champ.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def move
      @procedure.draft_revision.move_type_de_champ(type_de_champ_stable_id, (params[:position] || params[:order_place]).to_i)

      head :no_content
    end

    def destroy
      @procedure.draft_revision.remove_type_de_champ(type_de_champ_stable_id)
      reset_procedure

      head :no_content
    end

    private

    def type_de_champ_stable_id
      TypeDeChamp.find(params[:id]).stable_id
    end

    def revisions_migration
      # FIXUP: needed during transition to revisions
      RevisionsMigration.add_revisions(@procedure)
    end

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
            :batiments,
            :cadastres,
            :drop_down_list_value,
            :level,
            :parcelles,
            :parcelles_agricoles,
            :piece_justificative_template_filename,
            :piece_justificative_template_url,
            :quartiers_prioritaires,
            :zones_manuelles,
            :min,
            :max
          ]
        )
      }
    end

    def type_de_champ_create_params
      type_de_champ_params = params.required(:type_de_champ).permit(
        :batiments,
        :cadastres,
        :description,
        :drop_down_list_value,
        :level,
        :libelle,
        :mandatory,
        :order_place,
        :parcelles,
        :parcelles_agricoles,
        :parent_id,
        :piece_justificative_template,
        :private,
        :quartiers_prioritaires,
        :zones_manuelles,
        :min,
        :max,
        :type_champ
      )

      if type_de_champ_params[:parent_id].present?
        type_de_champ_params[:parent_id] = TypeDeChamp.find(type_de_champ_params[:parent_id]).stable_id
      end

      type_de_champ_params
    end

    def type_de_champ_update_params
      params.required(:type_de_champ).permit(
        :cadastres,
        :description,
        :drop_down_list_value,
        :level,
        :libelle,
        :mandatory,
        :parcelles_agricoles,
        :parcelles,
        :piece_justificative_template,
        :quartiers_prioritaires,
        :batiments,
        :zones_manuelles,
        :min,
        :max,
        :type_champ
      )
    end
  end
end
