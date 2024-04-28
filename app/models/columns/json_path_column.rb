# frozen_string_literal: true

class Columns::JSONPathColumn < Column
  def column
    "#{@column}->#{value_column}" # override column otherwise json path facets will have same id as other
  end

  def filtered_ids(dossiers, search_occurences)
    queries = Array.new(search_occurences.count, "(#{json_path_query_part} ILIKE ?)").join(' OR ')
    dossiers.with_type_de_champ(stable_id)
      .where(queries, *(search_occurences.map { |value| "%#{value}%" }))
      .ids
  end

  def options_for_select
    case value_column.last
    when 'departement_code'
      APIGeoService.departements.map { ["#{_1[:code]} – #{_1[:name]}", _1[:code]] }
    when 'region_name'
      APIGeoService.regions.map { [_1[:name], _1[:name]] }
    else
      []
    end
  end

  private

  def stable_id
    @column
  end

  # given a value_column as ['value_json', 'address', 'postal_code']
  # build SQL query as 'champs'.'value_json'->'address'->>'postal_code'
  # see: https://www.postgresql.org/docs/9.5/functions-json.html
  def json_path_query_part
    *json_segments, key = value_column

    if json_segments.blank? # not nested, only access using ->> Get JSON array element as text
      "#{quote_table_column('champs')}.#{quote_table_column('value_json')}->>#{quote_json_segment(key)}"
    else # nested, have to dig in json using -> Get JSON object field by key
      field_accessor = json_segments.map(&method(:quote_json_segment)).join('->')

      "#{quote_table_column('champs')}.#{quote_table_column('value_json')}->#{field_accessor}->>#{quote_json_segment(key)}"
    end
  end

  def quote_table_column(table_or_column)
    ActiveRecord::Base.connection.quote_column_name(table_or_column)
  end

  def quote_json_segment(path)
    "'#{path}'"
  end
end
