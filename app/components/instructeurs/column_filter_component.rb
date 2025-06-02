# frozen_string_literal: true

class Instructeurs::ColumnFilterComponent < ApplicationComponent
  attr_reader :procedure, :procedure_presentation, :statut, :column

  def initialize(procedure:, procedure_presentation:, statut:, column: nil)
    @procedure = procedure
    @procedure_presentation = procedure_presentation
    @statut = statut
    @column = column
  end

  def column_type = column.present? ? column.type : :text

  def options_for_select_of_column
    if column.scope.present?
      I18n.t(column.scope).map(&:to_a).map(&:reverse)
    elsif column.table == 'groupe_instructeur'
      current_instructeur.groupe_instructeurs.filter_map do
        if _1.procedure_id == procedure.id
          [_1.label, _1.id]
        end
      end
    else
      find_type_de_champ(column.column).options_for_select(column)
    end
  end

  def filter_react_props
    {
      selected_key: column.present? ? column.id : '',
      items: filterable_columns_options,
      name: :column,
      id: 'search-filter',
      'aria-describedby': 'instructeur-filter-combo-label',
      form: 'filter-component',
      data: { no_autosubmit: 'input blur', no_autosubmit_on_empty: 'true', autosubmit_target: 'input' }
    }
  end

  def filterable_columns_options
    procedure.columns.filter_map do |column|
      next if column.filterable == false

      [column.label, column.id]
    end
  end

  private

  def find_type_de_champ(column)
    TypeDeChamp
      .joins(:revision_types_de_champ)
      .where(revision_types_de_champ: { revision_id: procedure.revisions })
      .order(created_at: :desc)
      .find_by(stable_id: column)
  end
end
