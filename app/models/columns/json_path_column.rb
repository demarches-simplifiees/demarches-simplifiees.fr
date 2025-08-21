# frozen_string_literal: true

class Columns::JSONPathColumn < Columns::ChampColumn
  attr_reader :jsonpath

  def initialize(procedure_id:, label:, stable_id:, tdc_type:, jsonpath:, options_for_select: [], displayable:, filterable: true, type: :text, mandatory:)
    @jsonpath = quote_string(jsonpath)

    super(
      procedure_id:,
      label:,
      stable_id:,
      tdc_type:,
      displayable:,
      filterable:,
      type:,
      options_for_select:,
      mandatory:
    )
  end

  def filtered_ids(dossiers, filter)
    filtered_ids_for_values(dossiers, filter[:value])
  end

  def filtered_ids_for_values(dossiers, search_terms)
    value = quote_string(search_terms.join('|'))

    condition = %{champs.value_json @? '#{jsonpath} ? (@ like_regex "#{value}" flag "i")'}

    dossiers.with_type_de_champ(stable_id)
      .where(condition)
      .ids

  rescue ActiveRecord::StatementInvalid => e
    if e.cause.is_a?(PG::InvalidRegularExpression)
      Rails.logger.warn("filtered_ids fallback: Invalid regex — #{e.message}")
      []
    else
      raise
    end
  end

  private

  def column_id = "type_de_champ/#{stable_id}-#{jsonpath}"

  def typed_value(champ)
    JsonPath.on(champ.value_json, jsonpath).first
  end

  def quote_string(string) = ActiveRecord::Base.connection.quote_string(string)
end
