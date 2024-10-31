# frozen_string_literal: true

class Columns::LinkedDropDownColumn < Columns::ChampColumn
  def initialize(procedure_id:, label:, stable_id:, value_column:, displayable:, type: :text)
    super(
      procedure_id:,
      label:,
      stable_id:,
      displayable:,
      type:,
      value_column:
    )
  end

  def filtered_ids(dossiers, values)
    dossiers.with_type_de_champ(@column)
      .filter_ilike(:champs, :value, values)
      .ids
  end

  private

  def column_id
    if value_column == :value
      "type_de_champ/#{stable_id}"
    else
      "type_de_champ/#{stable_id}->#{path}"
    end
  end

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
