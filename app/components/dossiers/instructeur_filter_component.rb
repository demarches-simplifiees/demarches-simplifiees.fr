class Dossiers::InstructeurFilterComponent < ApplicationComponent
  def initialize(procedure:, procedure_presentation:, statut:, field_id: nil)
    @procedure = procedure
    @procedure_presentation = procedure_presentation
    @statut = statut
    @field_id = field_id
  end

  attr_reader :procedure, :procedure_presentation, :statut, :field_id

  def field_type
    return :text if field_id.nil?
    procedure_presentation.field_type(field_id)
  end

  def options_for_select_of_field
    procedure_presentation.field_enum(field_id)
  end

  def filter_react_props
    {
      selected_key: @field_id || '',
      items: procedure_presentation.filterable_fields_options,
      name: :field,
      id: 'search-filter',
      'aria-describedby': 'instructeur-filter-combo-label',
      form: 'filter-component',
      data: { no_autosubmit: 'input blur', no_autosubmit_on_empty: 'true', autosubmit_target: 'input' }
    }
  end
end
