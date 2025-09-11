# frozen_string_literal: true

class Instructeurs::RemoveFilterButtonsComponent < ApplicationComponent
  def initialize(filters:, procedure_presentation:, statut:)
    @filters = filters
    @procedure_presentation = procedure_presentation
    @statut = statut
  end

  def call
    safe_join(filters_by_family, t('.conjunctions.and'))
  end

  private

  def filters_by_family
    @filters
      .group_by { _1.column.id }
      .values
      .map { |group| group.map { |f| filter_form(f) } }
      .map { |group| safe_join(group, t('.conjunctions.or')) }
  end

  def filter_form(filter)
    button_to(
      remove_filter_instructeur_procedure_presentation_path(@procedure_presentation),
      method: :delete,
      class: 'fr-tag fr-tag--dismiss fr-my-1w fr-tag--sm',
      params: {
        filter: { id: filter.column.id, filter: filter.filter },
        statut: @statut
      }.compact,
      form: { data: { turbo: true } },
      form_class: 'inline'
    ) do
      button_content(filter)
    end
  end

  def button_content(filter)
    "#{filter.label.truncate(50)} : #{human_value(filter)}"
  end

  def human_value(filter_column)
    column_type = filter_column.column.type

    processed_value = if column_type == :date || column_type == :datetime
      filter_column.filter_value.map { helpers.try_parse_format_date(it) }.join(t('.conjunctions.or'))
    else
      filter_column.filter_value.map { filter_column.column.label_for_value(it) }.join(t('.conjunctions.or'))
    end

    [human_operator(filter_column.filter_operator), processed_value].compact_blank.join(' ')
  end

  def human_operator(operator)
    return "" if operator.in?(["in", "match"])

    t(".operators.#{operator}")
  end
end
