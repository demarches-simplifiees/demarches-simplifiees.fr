# frozen_string_literal: true

module Instructeurs
  class ProcedurePresentationController < InstructeurController
    before_action :set_procedure_presentation, only: [:update, :refresh_filters, :update_filter, :persist_filters, :toggle_filters_expanded, :customize_filters]

    # updates the value of a filter
    def update_filter
      @procedure_presentation.update_filter_for_statut!(params[:statut], params[:filter_key], filtered_column_from_params)

      render turbo_stream: turbo_stream.refresh
    end

    # updates the filters in customization without saving them
    def refresh_filters
      customize_filters_component = Instructeurs::CustomizeFiltersComponent.new(procedure_presentation: @procedure_presentation, statut: params[:statut], filters_columns: filters_columns_from_params)

      render turbo_stream: turbo_stream.replace(customize_filters_component.id, customize_filters_component)
    end

    def toggle_filters_expanded
      @procedure_presentation.update!(filters_expanded: params[:filters_expanded])

      editable_filters_component = Instructeurs::EditableFiltersComponent.new(procedure_presentation: @procedure_presentation, instructeur_procedure: @instructeur_procedure, statut: params[:statut])

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

    def persist_filters
      @procedure_presentation.replace_filters!(params[:statut], filters_columns_from_params)

      redirect_to instructeur_procedure_path(procedure, statut: params[:statut])
    end

    def customize_filters
      @procedure = @procedure_presentation.procedure
      @statut = params[:statut]
      @filters_columns = @procedure_presentation.filters_for(@statut).map(&:column)
      render layout: "empty_layout"
    end

    private

    def filters_columns_from_params
      Array(params[:filters_columns]).uniq.map { ColumnType.new.cast(it) }
    end

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
