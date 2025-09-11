# frozen_string_literal: true

class Columns::ChampColumn < Column
  attr_reader :stable_id, :tdc_type

  def initialize(procedure_id:, label:, stable_id:, tdc_type:, displayable: true, filterable: true, type: :text, options_for_select: [], mandatory:)
    @stable_id = stable_id
    @tdc_type = tdc_type
    column = tdc_type.in?(['departements', 'regions']) ? :external_id : :value

    super(
      procedure_id:,
      table: 'type_de_champ',
      column:,
      label:,
      type:,
      displayable:,
      filterable:,
      options_for_select:,
      mandatory:
    )
  end

  def value(champ)
    return if champ.nil?

    # nominal case
    if champ.is_type?(@tdc_type)
      typed_value(champ)
    else
      cast_value(champ)
    end
  end

  def filtered_ids(dossiers, filter)
    case filter
    in { operator: 'before', value: Array }
      filtered_ids_before_value(dossiers, filter[:value])
    in { operator: 'after', value: Array }
      filtered_ids_after_value(dossiers, filter[:value])
    in { operator: 'this_week' }
      filtered_ids_for_date_range(dossiers, Time.current.all_week)
    in { operator: 'this_month' }
      filtered_ids_for_date_range(dossiers, Time.current.all_month)
    in { operator: 'this_year' }
      filtered_ids_for_date_range(dossiers, Time.current.all_year)
    else
      filtered_ids_for_values(dossiers, filter[:value])
    end
  end

  def filtered_ids_before_value(dossiers, values)
    return dossiers.ids if values.first.blank?

    filtered_ids_for_date_range(dossiers, ..Time.zone.parse(values.first).beginning_of_day)
  end

  def filtered_ids_after_value(dossiers, values)
    return dossiers.ids if values.first.blank?

    filtered_ids_for_date_range(dossiers, (Time.zone.parse(values.first).end_of_day..))
  end

  def filtered_ids_for_date_range(dossiers, range)
    relation = dossiers.with_type_de_champ(stable_id)
    relation.where(champs: { column => range_for_query(range) }).ids
  end

  def filtered_ids_for_values(dossiers, search_terms)
    return dossiers.ids unless search_terms.any? { it.present? }

    return dossiers.without_type_de_champ(stable_id).ids if should_exclude_empty_values?(search_terms)

    relation = dossiers.with_type_de_champ(stable_id)

    if type == :enum
      relation.where(champs: { column => search_terms }).ids
    elsif type == :enums
      # in a multiple drop down list, the value are stored as '["v1", "v2"]'
      quoted_search_terms = search_terms.map { %{"#{_1}"} }
      relation.filter_ilike(:champs, column, quoted_search_terms).ids
    else
      relation.filter_ilike(:champs, column, search_terms).ids
    end
  end

  def should_exclude_empty_values?(search_terms)
    return true if tdc_type == "yes_no" && search_terms == [Column::NOT_FILLED_VALUE]
    return true if tdc_type == "checkbox" && search_terms == ["false"]

    false
  end

  def champ_column? = true

  private

  def range_for_query(date_range)
    start_date = date_range.begin&.then { type == :date ? _1.to_date : _1 }&.iso8601
    end_date = date_range.end&.then { type == :date ? _1.to_date : _1 }&.iso8601

    start_date..end_date
  end

  def column_id = "type_de_champ/#{stable_id}"

  def string_value(champ) = champ.public_send(column)

  def typed_value(champ)
    value = string_value(champ)

    return if value.blank?

    case type
    when :boolean
      parse_boolean(value)
    when :integer
      value.to_i
    when :decimal
      value.to_f
    when :datetime
      parse_datetime(value)
    when :date
      parse_datetime(value)&.to_date
    when :enum
      value
    when :enums
      parse_enums(value)
    else
      value
    end
  end

  def cast_value(champ)
    value = string_value(champ)

    return if value.blank?

    case [champ.last_write_type_champ, @tdc_type]
    when ['integer_number', 'decimal_number'] # recast numbers automatically
      value.to_f
    when ['decimal_number', 'integer_number'] # may lose some data, but who cares ?
      value.to_i
    when ['integer_number', 'text'], ['decimal_number', 'text'] # number to text
      value
    when ['drop_down_list', 'multiple_drop_down_list'] # single list can become multi
      [value]
    when ['drop_down_list', 'text'] # single list can become text
      value
    when ['multiple_drop_down_list', 'drop_down_list'] # multi list can become single
      parse_enums(value).first
    when ['multiple_drop_down_list', 'text'] # multi list can become text
      parse_enums(value).join(', ')
    when ['date', 'datetime'] # date <=> datetime
      parse_datetime(value)&.to_datetime
    when ['datetime', 'date'] # may lose some data, but who cares ?
      parse_datetime(value)&.to_date
    when ['formatted', 'text'], ['text', 'formatted'], ['text', 'textarea'], ['formatted', 'textarea']
      value
    else
      nil
    end
  end

  def parse_boolean(value)
    case value
    when 'true', 'on', '1'
      true
    when 'false'
      false
    end
  end

  def parse_enums(value) = JSON.parse(value) rescue nil

  def parse_datetime(value) = Time.zone.parse(value) rescue nil
end
