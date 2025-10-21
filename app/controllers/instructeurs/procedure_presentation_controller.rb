# frozen_string_literal: true

module Instructeurs
  class ProcedurePresentationController < InstructeurController
    before_action :set_procedure_presentation, only: [:update, :refresh_column_filter, :add_filter, :remove_filter, :update_filter, :toggle_filters_expanded, :toggle_filters_customization]

    def add_filter
      statut = params[:statut]

      if filter_params[:id].blank?
        flash.alert = I18n.t('views.instructeurs.dossiers.filters.missing_column')
        return redirect_back_or_to([:instructeur, procedure])
      end

      new_filter = filtered_column_from_params

      if new_filter.valid?
        @procedure_presentation.add_filter_for_statut!(statut, new_filter)
        flash.notice = "Filtre ajouté avec succès"
      else
        flash.alert = new_filter.errors.full_messages.join(', ')
      end

      redirect_back_or_to([:instructeur, procedure])
    end

    def update_filter
      @procedure_presentation.update_filter_for_statut!(params[:statut], params[:filter_key], filtered_column_from_params)

      render turbo_stream: turbo_stream.refresh
    end

    def remove_filter
      @procedure_presentation.remove_filter_for_statut!(params[:statut], filtered_column_from_params)
      if params[:filters_customization]
        render turbo_stream: turbo_stream.remove("customize-filter-#{filtered_column_from_params.id.parameterize}")
      else
        render turbo_stream: turbo_stream.refresh
      end
    end

    def toggle_filters_expanded
      @procedure_presentation.update!(filters_expanded: params[:filters_expanded])

      editable_filters_component = Instructeurs::EditableFiltersComponent.new(procedure_presentation: @procedure_presentation, instructeur_procedure: @instructeur_procedure, statut: params[:statut])

      render turbo_stream: turbo_stream.replace(editable_filters_component.id, editable_filters_component)
    end

    def toggle_filters_customization
      filters_customization = params[:filters_customization].in?([true, 'true'])
      editable_filters_component = Instructeurs::EditableFiltersComponent.new(procedure_presentation: @procedure_presentation, instructeur_procedure: @instructeur_procedure, statut: params[:statut], filters_customization:)

      render turbo_stream: turbo_stream.replace(editable_filters_component.id, editable_filters_component)
    end

    def update
      if !@procedure_presentation.update(procedure_presentation_params)
        # complicated way to display inner error messages
        flash.alert = @procedure_presentation.errors
          .flat_map { _1.detail[:value].flat_map { |c| c.errors.full_messages } }
      end

      redirect_back_or_to([:instructeur, procedure])
    end

    def refresh_column_filter
      @filtered_column = filtered_column_from_params
      @column = @filtered_column.column
      procedure = current_instructeur.procedures.find(@column.h_id[:procedure_id])
      @instructeur_procedure = InstructeursProcedure.find_by!(procedure:, instructeur: current_instructeur)

      if @column.groupe_instructeur?
        @column.options_for_select = current_instructeur.groupe_instructeur_options_for(procedure)
      end
    end

    private

    def filtered_column_from_params
      params_hash = filter_params.to_h.deep_stringify_keys
      params_hash['filter'] = ValueNormalizer.normalize(params_hash['filter']) if params_hash.key?('filter')

      FilteredColumnType.new.cast(params_hash)
    end

    def procedure = @procedure_presentation.procedure

    def procedure_presentation_params
      h = params.permit(displayed_columns: [], sorted_column: [:order, :id], filters: [:id, :filter]).to_h

      if params[:statut].present?
        filter_name = @procedure_presentation.filters_name_for(params[:statut])
        h[filter_name] = h.delete("filters") # move filters to the right key, ex: tous_filters
      end

      # React ComboBox/MultiComboBox return [''] when no value is selected
      # We need to remove them
      if h[:displayed_columns].present?
        h[:displayed_columns] = h[:displayed_columns].reject(&:empty?)
      end

      h
    end

    def filter_params
      if params[:filter].present? && params[:filter][:filter].is_a?(String) # old format
        params.require(:filter).permit(:id, :filter)
      else
        params.require(:filter).permit(:id, filter: [:operator, value: []])
      end
    end

    def set_procedure_presentation
      @procedure_presentation = ProcedurePresentation
        .includes(:assign_to)
        .find_by!(id: params[:id], assign_to: { instructeur: current_instructeur })
    end
  end
end
