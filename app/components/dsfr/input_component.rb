class Dsfr::InputComponent < ApplicationComponent
  delegate :object, to: :@form
  delegate :errors, to: :object

  # use it to indicate detailed about the inputs, ex: https://www.systeme-de-design.gouv.fr/elements-d-interface/modeles-et-blocs-fonctionnels/demande-de-mot-de-passe
  # it uses aria-describedby on input and link it to yielded content
  renders_one :describedby

  def initialize(form:, attribute:, input_type:, opts: {}, required: true)
    @form = form
    @attribute = attribute
    @input_type = input_type
    @opts = opts
    @required = required
  end

  # add invalid class on input when input is invalid
  # and and valid on input only if another input is invalid
  def input_group_opts
    opts = {
      class: class_names('fr-input-group': true,
                         'fr-password': password?,
                         "fr-input-group--error": errors_on_attribute?,
                         "fr-input-group--valid": !errors_on_attribute? && errors_on_another_attribute?)
    }
    if email?
      opts[:data] = { controller: 'email-input' }
    end
    opts
  end

  def label_opts
    { class: class_names('fr-label': true, 'fr-password__label': password?) }
  end

  def input_opts
    @opts[:class] = class_names(map_array_to_hash_with_true(@opts[:class])
                                  .merge('fr-password__input': password?,
                                         'fr-input': true,
                                         'fr-mb-0': true,
                                         'fr-input--error': errors_on_attribute?))

    if errors_on_attribute? || describedby
      @opts = @opts.deep_merge(aria: {
        describedby: error_message_id,
                                       invalid: errors_on_attribute?
      })
    end
    if @required
      @opts[:required] = true
    end
    if email?
      @opts = @opts.deep_merge(data: {
        action: "blur->email-input#checkEmail",
                                       'email-input-target': 'input'
      })
    end
    @opts
  end

  # errors helpers
  def errors_on_attribute?
    errors.has_key?(attribute_or_rich_body)
  end

  def error_message_id
    dom_id(object, @attribute)
  end

  def error_messages
    errors.full_messages_for(attribute_or_rich_body)
  end

  # i18n lookups
  def label
    object.class.human_attribute_name(@attribute)
  end

  def hint
    I18n.t("activerecord.attributes.#{object.class.name.underscore}.hints.#{@attribute}")
  end

  # kind of input helpers
  def password?
    @input_type == :password_field
  end

  def email?
    @input_type == :email_field
  end

  private

  def hint?
    I18n.exists?("activerecord.attributes.#{object.class.name.underscore}.hints.#{@attribute}")
  end

  def errors_on_another_attribute?
    !errors.empty?
  end

  # lookup for edge case from `form.rich_text_area`
  #   rich text uses _rich_#{attribute}, but it is saved on #{attribute}, as well as error messages
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
