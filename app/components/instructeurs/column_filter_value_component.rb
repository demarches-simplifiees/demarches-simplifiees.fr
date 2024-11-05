# frozen_string_literal: true

class Instructeurs::ColumnFilterValueComponent < ApplicationComponent
  attr_reader :column

  def initialize(column:)
    @column = column
  end

  def column_type = column.present? ? column.type : :text

  def call
    if column_type.in?([:enum, :enums, :boolean])
      select_tag :filter,
        options_for_select(options_for_select_of_column),
        id: 'value',
        name: "filters[][filter]",
        class: 'fr-select',
        data: { no_autosubmit: true }
    else
      tag.input(
        class: 'fr-input',
        id: 'value',
        type:,
        name: "filters[][filter]",
        maxlength: FilteredColumn::FILTERS_VALUE_MAX_LENGTH,
        disabled: column.nil? ? true : false,
        data: { no_autosubmit: true },
        required: true
      )
    end
  end

  private

  def type
    case column_type
    when :datetime, :date
      'date'
    when :integer, :decimal
      'number'
    else
      'text'
    end
  end

  def options_for_select_of_column
    if column.scope.present?
      I18n.t(column.scope).map(&:to_a).map(&:reverse)
    elsif column.table == 'groupe_instructeur'
      current_instructeur.groupe_instructeurs.filter_map do
        if _1.procedure_id == procedure_id
          [_1.label, _1.id]
        end
      end
    elsif column.table == 'dossier_labels'
      Procedure.find(procedure_id).labels.filter_map do
        [_1.name, _1.id]
      end
    else
      find_type_de_champ(column.column).options_for_select(column)
    end
  end

  def find_type_de_champ(column)
    stable_id = column.to_s.split('->').first
    TypeDeChamp
      .joins(:revision_types_de_champ)
      .where(revision_types_de_champ: { revision_id: ProcedureRevision.where(procedure_id:) })
      .order(created_at: :desc)
      .find_by(stable_id:)
  end

  def procedure_id = @column.h_id[:procedure_id]
end
