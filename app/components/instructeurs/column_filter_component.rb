# frozen_string_literal: true

class Instructeurs::ColumnFilterComponent < ApplicationComponent
  attr_reader :procedure, :procedure_presentation, :instructeur_procedure, :statut, :filtered_column

  def initialize(procedure_presentation:, statut:, instructeur_procedure:)
    @procedure_presentation = procedure_presentation
    @instructeur_procedure = instructeur_procedure
    @procedure = procedure_presentation.procedure
    @statut = statut
  end

  def filter_react_props
    {
      selected_key: filtered_column&.column ? filtered_column.column.id : '',
      items: filterable_columns_options,
      name: "filter[id]",
      id: 'search-filter',
      'aria-describedby': 'instructeur-filter-combo-label',
      form: 'filter-component',
      data: { no_autosubmit: 'input blur', no_autosubmit_on_empty: 'true', autosubmit_target: 'input' }
    }
  end

  def filterable_columns_options
    @procedure.columns.filter(&:filterable).map { [_1.label, _1.id] }
  end
end
