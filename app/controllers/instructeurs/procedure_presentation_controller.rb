# frozen_string_literal: true

module Instructeurs
  class ProcedurePresentationController < InstructeurController
    before_action :set_procedure_presentation

    def update
      if !@procedure_presentation.update(procedure_presentation_params)
        # complicated way to display inner error messages
        flash.alert = @procedure_presentation.errors
          .flat_map { _1.detail[:value].flat_map { |c| c.errors.full_messages } }
      end

      redirect_back_or_to([:instructeur, procedure])
    end

    def refresh_column_filter
      procedure_presentation = @procedure_presentation
      statut = params[:statut]
      current_filter = procedure_presentation.filters_name_for(statut)
      # According to the html, the selected column is the last one
      h_id = JSON.parse(params[current_filter].last[:id], symbolize_names: true)
      column = procedure.find_column(h_id:)

      filter_component = Instructeurs::ColumnFilterComponent.new(procedure:, procedure_presentation:, statut:, column:)

      render turbo_stream: turbo_stream.replace('filter-component', filter_component)
    end

    private

    def procedure = @procedure_presentation.procedure

    def procedure_presentation_params
      filters = [
        :tous_filters, :a_suivre_filters, :suivis_filters, :traites_filters,
        :expirant_filters, :archives_filters, :supprimes_filters
      ].index_with { [:id, :filter] }

      h = params.permit(displayed_columns: [], sorted_column: [:order, :id], **filters).to_h

      # React ComboBox/MultiComboBox return [''] when no value is selected
      # We need to remove them
      if h[:displayed_columns].present?
        h[:displayed_columns] = h[:displayed_columns].reject(&:empty?)
      end

      h
    end

    def set_procedure_presentation
      @procedure_presentation = ProcedurePresentation
        .includes(:assign_to)
        .find_by!(id: params[:id], assign_to: { instructeur: current_instructeur })
    end
  end
end
