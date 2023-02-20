class Dossiers::FilterComponent < ApplicationComponent
  def initialize(procedure:, procedure_presentation:, statut:, field_id: nil)
    @procedure = procedure
    @procedure_presentation = procedure_presentation
    @statut = statut
    @field_id = field_id
  end

  attr_reader :procedure, :procedure_presentation, :statut, :field_id

  def filterable_fields_for_select
    procedure_presentation.filterable_fields_options
  end

  def field_type
    return :text if field_id.nil?
    procedure_presentation.field_type(field_id)
  end

  def options_for_select_of_field
    I18n.t(procedure_presentation.field_enum(field_id)).map(&:to_a).map(&:reverse)
  end
end
