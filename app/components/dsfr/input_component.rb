class Dsfr::InputComponent < ApplicationComponent
  include Dsfr::InputErrorable

  delegate :object, to: :@form
  delegate :errors, to: :object

  # use it to indicate detailed about the inputs, ex: https://www.systeme-de-design.gouv.fr/elements-d-interface/modeles-et-blocs-fonctionnels/demande-de-mot-de-passe
  # it uses aria-describedby on input and link it to yielded content
  renders_one :describedby

  def initialize(form:, attribute:, input_type: :text_field, opts: {}, required: true)
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
      class: class_names({
        'fr-input-group': true,
        'fr-password': password?
      }.merge(input_group_error_class_names))
    }
    if email?
      opts[:data] = { controller: 'email-input' }
    end
    opts
  end

  def label_opts
    { class: class_names('fr-label': true, 'fr-password__label': password?) }
  end

  # errors helpers
  def error_messages
    errors.full_messages_for(attribute_or_rich_body)
  end

  def describedby_id
    dom_id(object, "#{@attribute}-messages")
  end

  # i18n lookups
  def label
    object.class.human_attribute_name(@attribute)
  end

  # kind of input helpers
  def password?
    @input_type == :password_field
  end

  def email?
    @input_type == :email_field
  end

  def show_password_id
    dom_id(object, "#{@attribute}_show_password")
  end

  private
end
