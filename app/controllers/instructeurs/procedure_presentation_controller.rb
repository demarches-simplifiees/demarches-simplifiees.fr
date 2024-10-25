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
      prefix = params[:prefix]
      key = prefix.gsub('[]', '')
      column = ColumnType.new.cast(params[key].last['id'])

      component = Instructeurs::ColumnFilterValueComponent.new(column:, prefix:)

      render turbo_stream: turbo_stream.replace('value', component)
    end

    private

    def procedure = @procedure_presentation.procedure

    def procedure_presentation_params
      # TODO: peut etre simplifier en transformer un parametre filter -> tous_filter, suivant le params statut


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
