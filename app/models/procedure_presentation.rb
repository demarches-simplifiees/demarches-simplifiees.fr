class ProcedurePresentation < ApplicationRecord
  EXTRA_SORT_COLUMNS = {
    'notifications' => Set['notifications'],
    'self' => Set['id', 'state']
  }

  belongs_to :assign_to

  delegate :procedure, to: :assign_to

  validate :check_allowed_displayed_fields
  validate :check_allowed_sort_column
  validate :check_allowed_filter_columns

  def check_allowed_displayed_fields
    displayed_fields.each do |field|
      table = field['table']
      column = field['column']
      if !dossier_field_service.valid_column?(procedure, table, column)
        errors.add(:filters, "#{table}.#{column} n’est pas une colonne permise")
      end
    end
  end

  def check_allowed_sort_column
    table = sort['table']
    column = sort['column']
    if !valid_sort_column?(procedure, table, column)
      errors.add(:sort, "#{table}.#{column} n’est pas une colonne permise")
    end
  end

  def check_allowed_filter_columns
    filters.each do |_, columns|
      columns.each do |column|
        table = column['table']
        column = column['column']
        if !dossier_field_service.valid_column?(procedure, table, column)
          errors.add(:filters, "#{table}.#{column} n’est pas une colonne permise")
        end
      end
    end
  end

  def fields
    dossier_field_service.fields(procedure)
  end

  def fields_for_select
    fields.map do |field|
      [field['label'], "#{field['table']}/#{field['column']}"]
    end
  end

  private

  def dossier_field_service
    @dossier_field_service ||= DossierFieldService.new
  end

  def valid_sort_column?(procedure, table, column)
    dossier_field_service.valid_column?(procedure, table, column) || EXTRA_SORT_COLUMNS[table]&.include?(column)
  end
end
