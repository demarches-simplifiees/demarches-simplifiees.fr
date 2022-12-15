class Dsfr::InputComponent < ApplicationComponent
  def initialize(form:, attribute:, input_type:, opts: {}, required: true)
    @form = form
    @attribute = attribute
    @input_type = input_type
    @opts = opts
    @required = required
  end

  def input_opts
    @opts[:class] = class_names(map_array_to_hash_with_true(@opts[:class])
                                  .merge('fr-input': true,
                                         'fr-mb-0': true,
                                         'fr-input--error': errors_on_attribute?))

    if errors_on_attribute?
      @opts = @opts.deep_merge(aria: {
        describedby: error_message_id,
                                       invalid: true
      })
    end
    if @required
      @opts[:required] = true
    end
    @opts
  end

  # add invalid class on input when input is invalid
  # and and valid on input only if another input is invalid
  def input_group_class_names
    class_names('fr-input-group': true,
                "fr-input-group--error": errors_on_attribute?,
                "fr-input-group--valid": !errors_on_attribute? && errors_on_another_attribute?)
  end

  # tried to inline it within the template, but failed miserably with a double render
  def label
    label = @form.object.class.human_attribute_name(@attribute)

    if @required
      label += tag.span(" *", class: 'mandatory')
    end
    label
  end

  def errors_on_attribute?
    @form.object.errors.has_key?(attribute_or_rich_body)
  end

  def error_message_id
    dom_id(@form.object, @attribute)
  end

  def error_messages
    @form.object.errors.full_messages_for(attribute_or_rich_body)
  end

  private

  def errors_on_another_attribute?
    !@form.object.errors.empty?
  end

  def attribute_or_rich_body
    case @input_type
    when :rich_text_area
      @attribute.to_s.sub(/\Arich_/, '').to_sym
    else
      @attribute
    end
  end

  def map_array_to_hash_with_true(array_or_string_or_nil)
    Array(array_or_string_or_nil).to_h { [_1, true] }
  end
end
