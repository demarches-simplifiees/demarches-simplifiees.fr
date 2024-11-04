# frozen_string_literal: true

class Columns::LinkedDropDownColumn < Column
  def column
    return super if default_column?
    "#{@column}->#{value_column}" # override column otherwise json path facets will have same id as other
  end

  def filtered_ids(dossiers, values)
    dossiers.with_type_de_champ(@column)
      .filter_ilike(:champs, :value, values)
      .ids
  end

  private

  def typed_value(champ)
    return nil if default_column?

    primary_value, secondary_value = unpack_values(champ.value)
    case value_column
    when :primary
      primary_value
    when :secondary
      secondary_value
    end
  end

  def unpack_values(value)
    JSON.parse(value)
  rescue JSON::ParserError
    []
  end
end
