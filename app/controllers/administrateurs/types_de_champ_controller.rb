module Administrateurs
  class TypesDeChampController < AdministrateurController
    before_action :retrieve_procedure
    after_action :reset_procedure, only: [:create, :update, :destroy, :piece_justificative_template]

    def create
      type_de_champ = draft.add_type_de_champ(type_de_champ_create_params)

      if type_de_champ.valid?
        @coordinate = draft.coordinate_for(type_de_champ)
        @created = champ_component_from(@coordinate, focused: true)
        # TODO: position, champ_components_starting_at. current+1
        # @morphed = champ_components_starting_at(@coordinate, :>)
        @morphed = champ_components_starting_at(@coordinate, 1)
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
        # TODO: position, champ_components_starting_at. current+0
        # @morphed = champ_components_starting_at(@coordinate, :==)
        @morphed = champ_components_starting_at(@coordinate)
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

    def notice_explicative
      type_de_champ = draft.find_and_ensure_exclusive_use(params[:stable_id])

      if type_de_champ.notice_explicative.attach(params[:blob_signed_id])
        @coordinate = draft.coordinate_for(type_de_champ)
        @morphed = [champ_component_from(@coordinate)]

        render :create
      else
        render json: { errors: @champ.errors.full_messages }, status: 422
      end
    end

    def move_and_morph
      source_type_de_champ = draft.find_and_ensure_exclusive_use(params[:stable_id])
      target_type_de_champ = draft.find_and_ensure_exclusive_use(params[:target_stable_id])
      @coordinate = draft.coordinate_for(source_type_de_champ)
      from = @coordinate.position
      to = draft.coordinate_for(target_type_de_champ).position
      @coordinate = draft.move_type_de_champ(@coordinate.stable_id, to)
      @destroyed = @coordinate
      @created = champ_component_from(@coordinate)
      @morphed = @coordinate.siblings
      if from > to # case of moved up, update components from target (> plus one) to origin
        @morphed = @morphed.where("position > ?", to).where("position <= ?", from)
      else # case of moved down, update components from origin up to target (< minus one)
        @morphed = @morphed.where("position >= ?", from).where("position < ?", to)
      end
      @morphed = @morphed.map { |c| champ_component_from(c) }
    end

    def move_up
      @coordinate = draft.move_up_type_de_champ(params[:stable_id])
      @destroyed = @coordinate
      @created = champ_component_from(@coordinate)
      # update the one component below
      # TODO: position, champ_components_starting_at. current+1
      # @morphed = champ_components_starting_at(@coordinate, :==).take(1)
      @morphed = champ_components_starting_at(@coordinate, 1).take(1)
    end

    def move_down
      @coordinate = draft.move_down_type_de_champ(params[:stable_id])
      @destroyed = @coordinate
      @created = champ_component_from(@coordinate)
      # update the one component above
      # TODO: position, champ_components_starting_at. current-1
      # @morphed = champ_components_starting_at(@coordinate, :<).take(1)
      @morphed = champ_components_starting_at(@coordinate, - 1).take(1)
    end

    def destroy
      coordinate, type_de_champ = draft.coordinate_and_tdc(params[:stable_id])

      if coordinate&.used_by_routing_rules?
        errors = "« #{type_de_champ.libelle} » est utilisé pour le routage, vous ne pouvez pas le supprimer."
        @morphed = [champ_component_from(coordinate, focused: false, errors:)]
        flash.alert = errors
      else
        @coordinate = draft.remove_type_de_champ(params[:stable_id])

        if @coordinate.present?
          @destroyed = @coordinate
          # TODO: position, champ_components_starting_at. current+0
          # @morphed = champ_components_starting_at(@coordinate, :==)
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
        upper_coordinates: coordinate.upper_coordinates,
        focused: focused,
        errors:
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
        :header_section_level,
        :character_limit,
        :expression_reguliere,
        :expression_reguliere_exemple_text,
        :expression_reguliere_error_message,
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
