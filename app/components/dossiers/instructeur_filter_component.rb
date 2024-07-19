class Dossiers::InstructeurFilterComponent < ApplicationComponent
  def initialize(procedure:, procedure_presentation:, statut:, facet: nil)
    @procedure = procedure
    @procedure_presentation = procedure_presentation
    @statut = statut
    @facet = facet
  end

  attr_reader :procedure, :procedure_presentation, :statut, :facet

  def facet_type = facet.present? ? facet.type : :text

  def options_for_select_of_field
    procedure_presentation.field_enum(field_id)
  end

  def filter_react_props
    {
      selected_key: facet.present? ? facet.id : '',
      items: procedure_presentation.filterable_fields_options,
      name: :field,
      id: 'search-filter',
      'aria-describedby': 'instructeur-filter-combo-label',
      form: 'filter-component',
      data: { no_autosubmit: 'input blur', no_autosubmit_on_empty: 'true', autosubmit_target: 'input' }
    }
  end
end
