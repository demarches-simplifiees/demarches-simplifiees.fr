class Dossiers::NotifiedToggleComponent < ApplicationComponent
  def initialize(procedure:, procedure_presentation:)
    @procedure = procedure
    @procedure_presentation = procedure_presentation
    @current_sort = procedure_presentation.sort
  end

  private

  def opposite_order
    @procedure_presentation.opposite_order_for(current_table, current_column)
  end

  def active?
    sorted_by_notifications? && order_asc?
  end

  def icon_class_name
    active? ? 'fr-fi-checkbox' : 'fr-fi-checkbox-blank'
  end

  def order_asc?
    current_order == 'asc'
  end

  def current_order
    @current_sort['order']
  end

  def current_table
    @current_sort['table']
  end

  def current_column
    @current_sort['column']
  end

  def sorted_by_notifications?
    current_table == 'notifications' && current_column == 'notifications'
  end
end
