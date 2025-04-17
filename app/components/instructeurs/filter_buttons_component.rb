# frozen_string_literal: true

class Instructeurs::FilterButtonsComponent < ApplicationComponent
  def initialize(filters:, procedure_presentation:, statut:)
    @filters = filters
    @procedure_presentation = procedure_presentation
    @statut = statut
  end

  def call
    safe_join(filters_by_family, ' et ')
  end

  private

  def filters_by_family
    @filters
      .group_by { _1.column.id }
      .values
      .map { |group| group.map { |f| filter_form(f) } }
      .map { |group| safe_join(group, ' ou ') }
  end

  def filter_form(filter)
    form_with(model: [:instructeur, @procedure_presentation], class: 'inline') do
      safe_join([
        hidden_field_tag('filters[]', ''),    # to ensure the filters is not empty
        *other_hidden_fields(filter),         # other filters to keep
        hidden_field_tag('statut', @statut),  # collection to set
        button_tag(button_content(filter), class: 'fr-tag fr-tag--dismiss fr-my-1w fr-tag--sm')
      ])
    end
  end

  def other_hidden_fields(filter)
    @filters.reject { _1 == filter }.flat_map do |f|
      [
        hidden_field_tag("filters[][id]", f.column.id),
        hidden_field_tag("filters[][filter]", f.filter)
      ]
    end
  end

  def button_content(filter)
    "#{filter.label.truncate(50)} : #{human_value(filter)}"
  end

  def human_value(filter_column)
    column, filter = filter_column.column, filter_column.filter

    if column.type == :date || column.type == :datetime
      helpers.try_parse_format_date(filter)
    else
      column.label_for_value(filter)
    end
  end
end
