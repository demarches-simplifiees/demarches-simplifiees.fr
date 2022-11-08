module Administrateurs
  class TypesDeChampController < AdministrateurController
    before_action :retrieve_procedure, :procedure_revisable?

    def create
      type_de_champ = draft.add_type_de_champ(type_de_champ_create_params)

      if type_de_champ.valid?
        @coordinate = draft.coordinate_for(type_de_champ)
        @created = champ_component_from(@coordinate, focused: true)
        @morphed = champ_components_starting_at(@coordinate, 1)

        reset_procedure
        flash.notice = "Formulaire enregistré"
      else
        flash.alert = type_de_champ.errors.full_messages
      end
    end

    def update
      type_de_champ = draft.find_and_ensure_exclusive_use(params[:stable_id])

      if type_de_champ.update(type_de_champ_update_params)
        @coordinate = draft.coordinate_for(type_de_champ)
        @morphed = champ_components_starting_at(@coordinate)

        reset_procedure
        flash.notice = "Formulaire enregistré"
      else
        flash.alert = type_de_champ.errors.full_messages
      end
    end

    def piece_justificative_template
      type_de_champ = draft.find_and_ensure_exclusive_use(params[:stable_id])

      if type_de_champ.piece_justificative_template.attach(params[:blob_signed_id])
        @coordinate = draft.coordinate_for(type_de_champ)
        @morphed = [champ_component_from(@coordinate)]

        render :create
      else
        render json: { errors: @champ.errors.full_messages }, status: 422
      end
    end

    def move
      flash.notice = "Formulaire enregistré"
      draft.move_type_de_champ(params[:stable_id], params[:position].to_i)
    end

    def move_up
      flash.notice = "Formulaire enregistré"
      @coordinate = draft.move_up_type_de_champ(params[:stable_id])
      @destroyed = @coordinate
      @created = champ_component_from(@coordinate)
      # update the one component below
      @morphed = champ_components_starting_at(@coordinate, 1).take(1)
    end

    def move_down
      flash.notice = "Formulaire enregistré"
      @coordinate = draft.move_down_type_de_champ(params[:stable_id])
      @destroyed = @coordinate
      @created = champ_component_from(@coordinate)
      # update the one component above
      @morphed = champ_components_starting_at(@coordinate, - 1).take(1)
    end

    def destroy
      @coordinate = draft.remove_type_de_champ(params[:stable_id])
      reset_procedure
      flash.notice = "Formulaire enregistré"

      if @coordinate.present?
        @destroyed = @coordinate
        @morphed = champ_components_starting_at(@coordinate)
      end
    end

    private

    def champ_components_starting_at(coordinate, offset = 0)
      coordinate
        .siblings_starting_at(offset)
        .lazy
        .map { |c| champ_component_from(c) }
    end

    def champ_component_from(coordinate, focused: false)
      TypesDeChampEditor::ChampComponent.new(
        coordinate: coordinate,
        upper_coordinates: coordinate.upper_siblings,
        focused: focused
      )
    end

    def type_de_champ_create_params
      params
        .required(:type_de_champ)
        .permit(:type_champ, :parent_stable_id, :private, :libelle, :after_stable_id)
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
        :collapsible_explanation_enabled,
        :collapsible_explanation_text,
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

    def draft
      @procedure.draft_revision
    end
  end
end
