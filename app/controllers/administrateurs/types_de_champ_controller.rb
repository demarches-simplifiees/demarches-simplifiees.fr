module Administrateurs
  class TypesDeChampController < AdministrateurController
    before_action :retrieve_procedure
    after_action :reset_procedure, only: [:create, :update, :destroy, :piece_justificative_template]

    def create
      type_de_champ = draft.add_type_de_champ(type_de_champ_create_params)

      if type_de_champ.valid?
        @coordinate = draft.coordinate_for(type_de_champ)
        @created = champ_component_from(@coordinate, focused: true)
        @morphed = champ_components_starting_at(@coordinate, 1)

        flash.notice = "Formulaire enregistré"
      else
        flash.alert = type_de_champ.errors.full_messages
      end
    end

    def update
      type_de_champ = draft.find_and_ensure_exclusive_use(params[:stable_id])

      if type_de_champ.revision_type_de_champ.used_by_routing_rules? && changing_of_type?(type_de_champ)
        coordinate = draft.coordinate_for(type_de_champ)
        errors = "« #{type_de_champ.libelle} » est utilisé pour le routage, vous ne pouvez pas modifier son type."
        @morphed = [champ_component_from(coordinate, focused: false, errors:)]
        flash.alert = errors
      elsif type_de_champ.update(type_de_champ_update_params)
        @coordinate = draft.coordinate_for(type_de_champ)
        @morphed = champ_components_starting_at(@coordinate)

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
      coordinate, type_de_champ = draft.coordinate_and_tdc(params[:stable_id])

      if coordinate.used_by_routing_rules?
        errors = "« #{type_de_champ.libelle} » est utilisé pour le routage, vous ne pouvez pas le supprimer."
        @morphed = [champ_component_from(coordinate, focused: false, errors:)]
        flash.alert = errors
      else
        @coordinate = draft.remove_type_de_champ(params[:stable_id])
        flash.notice = "Formulaire enregistré"

        if @coordinate.present?
          @destroyed = @coordinate
          @morphed = champ_components_starting_at(@coordinate)
        end
      end
    end

    private

    def changing_of_type?(type_de_champ)
      type_de_champ_update_params['type_champ'].present? && (type_de_champ_update_params['type_champ'] != type_de_champ.type_champ)
    end

    def champ_components_starting_at(coordinate, offset = 0)
      coordinate
        .siblings_starting_at(offset)
        .lazy
        .map { |c| champ_component_from(c) }
    end

    def champ_component_from(coordinate, focused: false, errors: '')
      TypesDeChampEditor::ChampComponent.new(
        coordinate:,
        upper_coordinates: coordinate.upper_siblings,
        focused: focused,
        errors:
      )
    end

    def type_de_champ_create_params
      params
        .required(:type_de_champ)
        .permit(:type_champ, :parent_stable_id, :private, :libelle, :after_stable_id)
    end

    INSTANCE_PARAMS = TypeDeChamp::INSTANCE_OPTIONS.map { |tdc| tdc != :accredited_users ? tdc : :accredited_user_string }
    INSTANCE_EDITABLE_OPTIONS = TypesDeChamp::TeFenuaTypeDeChamp::LAYERS

    def type_de_champ_update_params
      params.required(:type_de_champ).permit(:type_champ,
        *INSTANCE_PARAMS,
        :libelle,
        :description,
        :mandatory,
        :drop_down_list_value,
        :drop_down_other,
        :drop_down_secondary_libelle,
        :drop_down_secondary_description,
        :collapsible_explanation_enabled,
        :collapsible_explanation_text,
        :header_section_level,
        editable_options: [
          *INSTANCE_EDITABLE_OPTIONS,
          *TypesDeChamp::CarteTypeDeChamp::LAYERS
        ])
    end

    def draft
      @procedure.draft_revision
    end
  end
end
