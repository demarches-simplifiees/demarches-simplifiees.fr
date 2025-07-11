# frozen_string_literal: true

module Instructeurs
  class ProcedurePresentationController < InstructeurController
    before_action :set_procedure_presentation, only: [:update, :refresh_column_filter, :add_filter, :remove_filter]

    def add_filter
      column = ColumnType.new.cast(filter_params[:column_id])
      filter_value = filter_params[:filter_value]
      or_filter_value = filter_params[:or_filter_value]
      statut = filter_params[:statut]

      new_filter = FilteredColumn.new(column: column, filter: filter_value, or_filter: or_filter_value)

      if new_filter.valid?
        filters_attr = @procedure_presentation.filters_name_for(statut)
        current_filters = @procedure_presentation.send(filters_attr) || []
        @procedure_presentation.update!(filters_attr => current_filters + [new_filter])
        flash.notice = "Filtre ajouté avec succès"
      else
        flash.alert = new_filter.errors.full_messages.join(', ')
      end

      redirect_back_or_to([:instructeur, procedure])
    end

    def remove_filter
      filter_name = @procedure_presentation.filters_name_for(params[:statut])

      @procedure_presentation.update!(filter_name => @procedure_presentation.filters_for(params[:statut]).reject do |filter|
        filtered_column_from_params == filter
      end)

      redirect_back_or_to([:instructeur, procedure])
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
      @column = filtered_column_from_params.column
      procedure = current_instructeur.procedures.find(@column.h_id[:procedure_id])

      if @column.groupe_instructeur?
        @column.options_for_select = current_instructeur.groupe_instructeur_options_for(procedure)
      end
    end

    private

    def filtered_column_from_params
      @filtered_column_from_params ||= FilteredColumn.new(column: ColumnType.new.cast(params[:column_id]), filter: params[:filter], or_filter: params[:or_filter])
    end

    def procedure = @procedure_presentation.procedure

    def procedure_presentation_params
      h = params.permit(displayed_columns: [], sorted_column: [:order, :id], filters: [:id, :filter, or_filter: []]).to_h

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
      params.permit(:column_id, :filter_value, :statut, or_filter_value: [])
    end

    def set_procedure_presentation
      @procedure_presentation = ProcedurePresentation
        .includes(:assign_to)
        .find_by!(id: params[:id], assign_to: { instructeur: current_instructeur })
    end
  end
end
