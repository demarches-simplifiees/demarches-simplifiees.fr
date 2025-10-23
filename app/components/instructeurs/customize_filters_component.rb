# frozen_string_literal: true

class Instructeurs::CustomizeFiltersComponent < ApplicationComponent
  attr_reader :procedure_presentation, :statut, :filters_columns

  def initialize(procedure_presentation:, statut:, filters_columns:)
    @procedure_presentation = procedure_presentation
    @statut = statut
    @filters_columns = filters_columns
  end

  def id
    "customize-filters-component"
  end

  def filters_selects
    [
      {
        label: t('.file_information'),
        items: dossier_filter_items
      },
      {
        label: t('.user_information'),
        items: usager_filter_items
      },
      {
        label: t('.user_form'),
        items: form_filter_items
      },
      {
        label: t('.private_annotations'),
        items: annotation_filter_items
      }
    ]
  end

  def delete_button(filter_column)
    button_to(
      refresh_filters_instructeur_procedure_presentation_path(@procedure_presentation),
      method: :post,
      class: 'fr-btn fr-btn--sm fr-btn--tertiary-no-outline fr-icon-delete-line',
      params: {
        filters_columns: filters_columns.filter { _1.id != filter_column.id }.map(&:id),
        statut: @statut
      }.compact,
      form: { data: { turbo: true, turbo_force: :server } },
      form_class: 'inline'
    ) do
      t('.delete_filter', filter_label: filter_column.label)
    end
  end

  def procedure
    @procedure_presentation.procedure
  end

  def dossier_filter_items
    {
      "-- #{t('.file_section')} --" => procedure.dossier_filterable_columns,
      "-- #{t('.instructors_section')} --" => procedure.instructeurs_filterable_columns
    }.transform_values { it.map { [_1.label, _1.id] } }
  end

  def disabled_items
    @disabled_items ||= filters_columns.map(&:id)
  end

  def filters_in_hidden_inputs(form, form_prefix)
    # form_prefix is used to avoid id conflicts with other forms on the page
    safe_join([
      *filters_columns.map { |filter| form.hidden_field "filters_columns[]", value: filter.id, id: "#{form_prefix}-filter-#{filter.id.parameterize}" },
      form.hidden_field("statut", value: @statut, id: "#{form_prefix}-statut")
    ])
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
