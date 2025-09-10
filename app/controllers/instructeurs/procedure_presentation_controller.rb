# frozen_string_literal: true

module Instructeurs
  class ProcedurePresentationController < InstructeurController
    before_action :set_procedure_presentation, only: [:update, :refresh_column_filter, :add_filter, :remove_filter]

    def add_filter
      statut = params[:statut]

      new_filter = filtered_column_from_params

      if new_filter.valid?
        @procedure_presentation.add_filter_for_statut!(statut, new_filter)
        flash.notice = "Filtre ajouté avec succès"
      else
        flash.alert = new_filter.errors.full_messages.join(', ')
      end

      redirect_back_or_to([:instructeur, procedure])
    end

    def remove_filter
      @procedure_presentation.remove_filter_for_statut!(params[:statut], filtered_column_from_params)

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
      @filtered_column = filtered_column_from_params
      @column = @filtered_column.column
      procedure = current_instructeur.procedures.find(@column.h_id[:procedure_id])

      if @column.groupe_instructeur?
        @column.options_for_select = current_instructeur.groupe_instructeur_options_for(procedure)
      end
    end

    private

    def filtered_column_from_params
      FilteredColumnType.new.cast(filter_params.to_h)
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
