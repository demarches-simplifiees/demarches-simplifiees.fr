# frozen_string_literal: true

class Columns::LinkedDropDownColumn < Columns::ChampColumn
  attr_reader :path

  def initialize(procedure_id:, label:, stable_id:, tdc_type:, path:, options_for_select: [], displayable:, type: :text)
    @path = path

    super(
      procedure_id:,
      label:,
      stable_id:,
      tdc_type:,
      displayable:,
      type:,
      options_for_select:
    )
  end

  def filtered_ids(dossiers, values)
    dossiers.with_type_de_champ(@column)
      .filter_ilike(:champs, :value, values)
      .ids
  end

  private

  def column_id = "type_de_champ/#{stable_id}->#{path}"

  def typed_value(champ)
    return nil if path == :value

    primary_value, secondary_value = unpack_values(champ.value)
    case path
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
