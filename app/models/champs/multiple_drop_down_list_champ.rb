class Champs::MultipleDropDownListChamp < Champ
  validate :values_are_in_options, if: -> { value.present? && validate_champ_value_or_prefill? }

  def options?
    drop_down_list_options?
  end

  def enabled_non_empty_options
    drop_down_list_enabled_non_empty_options
  end

  THRESHOLD_NB_OPTIONS_AS_CHECKBOX = 5

  def search_terms
    selected_options
  end

  def selected_options
    value.blank? ? [] : JSON.parse(value)
  end

  def render_as_checkboxes?
    enabled_non_empty_options.size <= THRESHOLD_NB_OPTIONS_AS_CHECKBOX
  end

  def html_label?
    !render_as_checkboxes?
  end

  def legend_label?
    true
  end

  def single_checkbox?
    render_as_checkboxes?
  end

  def blank?
    selected_options.blank?
  end

  def in?(options)
    (selected_options - options).size != selected_options.size
  end

  def remove_option(options, touch = false)
    value = (selected_options - options).to_json
    if touch
      update(value:)
    else
      update_columns(value:)
    end
  end

  def focusable_input_id
    render_as_checkboxes? ? checkbox_id(enabled_non_empty_options.first) : input_id
  end

  def checkbox_id(value)
    "#{input_id}-#{Digest::MD5.hexdigest(value)}"
  end

  def next_checkbox_id(value)
    return nil if value.blank? || !selected_options.include?(value)
    index = selected_options.index(value)
    next_values = selected_options.reject { _1 == value }
    next_value = next_values[index] || next_values.last
    next_value ? checkbox_id(next_value) : nil
  end

  def unselected_options
    enabled_non_empty_options - selected_options
  end

  def value=(value)
    return super(nil) if value.nil?

    values = if value.is_a?(Array)
      value
    elsif value.starts_with?('[')
      JSON.parse(value) rescue selected_options + [value] # value may start by [ without being a real JSON value
    else
      selected_options + [value]
    end.uniq.without('')

    if values.empty?
      super(nil)
    else
      super(values.to_json)
    end
  end

  private

  def values_are_in_options
    json = selected_options.compact_blank
    return if json.empty?
    return if (json - enabled_non_empty_options).empty?

    errors.add(:value, :not_in_options)
  end
end
