# frozen_string_literal: true

class Instructeurs::CustomizeFiltersComponent < ApplicationComponent
  attr_reader :procedure_presentation, :statut, :instructeur_procedure, :filters_customization

  def initialize(procedure_presentation:, instructeur_procedure:, statut:, filters_customization: false)
    @procedure_presentation = procedure_presentation
    @instructeur_procedure = instructeur_procedure
    @statut = statut
    @filters_customization = filters_customization
  end

  def id
    "customize-filters-component"
  end

  def delete_button(filter)
    button_to(
      remove_filter_instructeur_procedure_presentation_path(@procedure_presentation),
      method: :delete,
      class: 'fr-btn fr-btn--sm fr-btn--tertiary-no-outline fr-icon-delete-line',
      params: {
        filter: { id: filter.column.id, filter: filter.filter },
        statut: @statut,
        filters_customization: true
      }.compact,
      form: { data: { turbo: true } },
      form_class: 'inline'
    ) do
      t('.delete_filter', filter_label: filter.label)
    end
  end

  def filters
    procedure_presentation.filters_for(statut)
  end

  def procedure
    @procedure_presentation.procedure
  end

  def dossier_filter_items
    {
      "-- #{t('.file_section')} --" => procedure.dossier_filterable_columns,
      "-- #{t('.instructors_section')} --" => procedure.instructeurs_filterable_columns,
    }.transform_values { it.map { [_1.label, _1.id] } }
  end

  def usager_filter_items
    procedure.usager_filterable_columns.map { [_1.label, _1.id] }
  end

  def form_filter_items
    procedure.form_filterable_columns.map { [_1.label, _1.id] }
  end

  def annotation_filter_items
    procedure.annotation_privees_filterable_columns.map { [_1.label, _1.id] }
  end
end
