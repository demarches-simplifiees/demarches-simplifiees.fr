class Instructeurs::FacetTableHeaderComponent < ApplicationComponent
  attr_reader :procedure_presentation, :facet
  # maybe extract a FacetSorter class?
  #

  def initialize(procedure_presentation:, facet:)
    @procedure_presentation = procedure_presentation
    @facet = facet
  end

  def facet_id
    facet.id
  end

  def sorted_by_current_facet?
    procedure_presentation.sort['table'] == facet.table &&
    procedure_presentation.sort['column'] == facet.column
  end

  def sorted_ascending?
    current_sort_order == 'asc'
  end

  def sorted_descending?
    current_sort_order == 'desc'
  end

  def aria_sort
    if sorted_by_current_facet?
      if sorted_ascending?
        { "aria-sort": "ascending" }
      elsif sorted_descending?
        { "aria-sort": "descending" }
      end
    else
      {}
    end
  end

  private

  def current_sort_order
    procedure_presentation.sort['order']
  end
end
