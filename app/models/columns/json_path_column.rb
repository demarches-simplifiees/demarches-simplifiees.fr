# frozen_string_literal: true

class Columns::JSONPathColumn < Column
  attr_reader :stable_id, :jsonpath

  def initialize(label:, stable_id:, jsonpath:, type: :text)
    @stable_id = stable_id
    @jsonpath = jsonpath

    # currently, the column are searched by id = "#{table}/#{column}"
    # so we have add jsonpath to the column to make it unique
    super(
      table: 'type_de_champ',
      column: "#{stable_id}-#{jsonpath}",
      label:,
      type:
    )
  end

  def filtered_ids(dossiers, search_occurences)
    search_term = search_occurences.map { quote_string(_1) }.join('|')
    safe_jsonpath = jsonpath.split('.').map { quote_string(_1) }.join('.')

    condition = %{champs.value_json @? '#{safe_jsonpath} ? (@ like_regex "(#{search_term})" flag "i")'}

    dossiers.with_type_de_champ(stable_id)
      .where(condition)
      .ids
  end

  def options_for_select
    case jsonpath.split('.').last
    when 'departement_code'
      APIGeoService.departements.map { ["#{_1[:code]} – #{_1[:name]}", _1[:code]] }
    when 'region_name'
      APIGeoService.regions.map { [_1[:name], _1[:name]] }
    else
      []
    end
  end

  def champ_value(champ)
    Hash(champ.value_json).dig(*value_column)
  end

  private

  def quote_string(string) = ActiveRecord::Base.connection.quote_string(string)
end
