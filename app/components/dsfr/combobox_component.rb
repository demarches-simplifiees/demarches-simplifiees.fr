class Dsfr::ComboboxComponent < ApplicationComponent
  def initialize(form: nil, options:, selected: nil, allows_custom_value: false, **html_options)
    @form, @options, @selected, @allows_custom_value, @html_options = form, options, selected, allows_custom_value, html_options
  end

  attr_reader :form, :options, :selected, :allows_custom_value

  private

  def name
    @html_options[:name]
  end

  def form_id
    @html_options[:form_id]
  end

  def html_input_options
    {
      type: 'text',
      autocomplete: 'off',
      spellcheck: 'false',
      id: input_id,
      class: input_class,
      value: input_value,
      'aria-expanded': 'false',
      'aria-describedby': @html_options[:describedby]
    }.compact
  end

  def input_id
    @html_options[:id]
  end

  def input_class
    "#{@html_options[:class].presence || ''} fr-select"
  end

  def input_value
    selected.present? ? options_with_values.find { _1.last == selected }&.first : nil
  end

  def list_id
    input_id.present? ? "#{input_id}-list" : nil
  end

  def options_with_values
    options.map { _1.is_a?(Array) ? _1 : [_1, _1] }
  end

  def options_json
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
