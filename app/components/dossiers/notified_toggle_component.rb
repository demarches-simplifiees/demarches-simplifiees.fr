# frozen_string_literal: true

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
    sorted_by_notifications? && order_desc?
  end

  def order_desc?
    current_order == 'desc'
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
