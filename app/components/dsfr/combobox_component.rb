class Dsfr::ComboboxComponent < ApplicationComponent
  def initialize(form: nil, options: nil, url: nil, selected: nil, allows_custom_value: false, input_html_options: {}, hidden_html_options: {})
    @form, @options, @url, @selected, @allows_custom_value, @input_html_options, @hidden_html_options = form, options, url, selected, allows_custom_value, input_html_options, hidden_html_options
  end

  attr_reader :form, :options, :url, :selected, :allows_custom_value

  private

  def name
    @input_html_options[:name]
  end

  def form_id
    @input_html_options[:form_id]
  end

  def html_input_options
    {
      type: 'text',
      autocomplete: 'off',
      spellcheck: 'false',
      id: input_id,
      class: input_class,
      role: 'combobox',
      'aria-expanded': 'false',
      'aria-describedby': @input_html_options[:describedby]
    }.compact
  end

  def input_id
    @input_html_options[:id]
  end

  def input_class
    class_names(
      "#{@input_html_options[:class]}": @input_html_options[:class].presence,
      'fr-select': true,
      'fr-autocomplete': @url.presence
    )
  end

  def selected_option_label_input_value
    if selected.is_a?(Array) && selected.size == 2
      selected.first
    elsif options.present?
      selected.present? ? options_with_values.find { _1.last == selected }&.first : nil
    else
      selected
    end
  end

  def selected_option_value_input_value
    if selected.is_a?(Array) && selected.size == 2
      selected.last
    else
      selected
    end
  end

  def list_id
    input_id.present? ? "#{input_id}-list" : nil
  end

  def options_with_values
    return [] if url.present?
    options.map { _1.is_a?(Array) ? _1 : [_1, _1] }
  end

  def options_json
    return nil if url.present?
    options_with_values.map { |(label, value)| { label:, value: } }.to_json
  end

  def hints_json
    {
      empty: t(".sr.results", count: 0),
      one: t(".sr.results", count: 1),
      many: t(".sr.results", count: 2),
      oneWithLabel: t(".sr.results_with_label", count: 1),
      manyWithLabel: t(".sr.results_with_label", count: 2),
      selected: t(".sr.selected", count: 2)
    }.to_json
  end
end
