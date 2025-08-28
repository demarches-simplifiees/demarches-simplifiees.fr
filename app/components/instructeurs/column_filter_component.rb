# frozen_string_literal: true

class Instructeurs::ColumnFilterComponent < ApplicationComponent
  attr_reader :procedure, :procedure_presentation, :instructeur_procedure, :statut, :column

  def initialize(procedure_presentation:, statut:, instructeur_procedure:, column: nil)
    @procedure_presentation = procedure_presentation
    @instructeur_procedure = instructeur_procedure
    @procedure = procedure_presentation.procedure
    @statut = statut
    @column = column
  end

  def filter_react_props
    {
      selected_key: column.present? ? column.id : '',
      items: filterable_columns_options,
      name: "filters[][id]",
      id: 'search-filter',
      'aria-describedby': 'instructeur-filter-combo-label',
      form: 'filter-component',
      data: { no_autosubmit: 'input blur', no_autosubmit_on_empty: 'true', autosubmit_target: 'input' }
    }
  end

  def filterable_columns_options
    @procedure.columns.filter(&:filterable).map { [_1.label, _1.id] }
  end

  def current_filter_tags
    @procedure_presentation.filters_for(@statut).flat_map do
      [
        hidden_field_tag("filters[][id]", _1.column.id, id: nil),
        hidden_field_tag("filters[][filter]", _1.filter, id: nil)
      ]
    end.reduce(&:concat)
  end
end
