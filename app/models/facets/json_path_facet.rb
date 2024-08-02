class Facets::JSONPathFacet < Facet
  def column
    "#{@column}->#{value_column}" # override column otherwise json path facets will have same id as other
  end

  def filtered_ids(dossiers, communes)
    queries = Array.new(communes.count, "(#{query} ILIKE ?)").join(' OR ')

    dossiers.with_type_de_champ(stable_id)
      .where(queries, *(communes.map { |value| "%#{value}%" }))
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

  def query
    facet_column, *json_segments, key = value_column
    quoted_table_and_column = ["champs", facet_column].map(&method(:quote_table_column))
    quoted_json_segments = json_segments.map(&method(:quote_json_segment))

    table_name_with_segments = [
      quoted_table_and_column.join('.'),
      quoted_json_segments.present? ? quoted_json_segments.join('->') : nil
    ].compact.join('->') # json request expect format as `column`->`object_accessor`->`sub_accessor`
    "#{table_name_with_segments}->>#{quote_json_segment(key)}"
  end

  def quote_table_column(table_or_column)
    ActiveRecord::Base.connection.quote_column_name(table_or_column)
  end

  def quote_json_segment(path)
    "'#{path}'"
  end
end
