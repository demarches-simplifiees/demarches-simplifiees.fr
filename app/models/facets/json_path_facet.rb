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

  private

  def stable_id
    @column
  end

  def query
    facet_column, *json_segments, key = value_column
    quoted_table_and_column = ["champs", facet_column].map(&method(:quote_table_column))
    quoted_json_segments = json_segments.map(&method(:quote_json_segment))
    "#{quoted_table_and_column.join('.')}->#{quoted_json_segments.join('->')}->>#{quote_json_segment(key)}"
  end

  def quote_table_column(table_or_column)
    ActiveRecord::Base.connection.quote_column_name(table_or_column)
  end

  def quote_json_segment(path)
    "'#{path}'"
  end
end
