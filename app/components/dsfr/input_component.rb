# frozen_string_literal: true

class Dsfr::InputComponent < ApplicationComponent
  include Dsfr::InputErrorable

  delegate :object, to: :@form
  delegate :errors, to: :object

  attr_reader :attribute

  # use it to indicate detailed about the inputs, ex: https://www.systeme-de-design.gouv.fr/elements-d-interface/modeles-et-blocs-fonctionnels/demande-de-mot-de-passe
  # it uses aria-describedby on input and link it to yielded content
  renders_one :describedby
  renders_one :label

  def initialize(form:, attribute:, input_type: :text_field, opts: {}, required: true, autoresize: true, label_opts: {})
    @form = form
    @attribute = attribute
    @input_type = input_type
    @opts = opts
    @required = required
    @autoresize = autoresize
    @label_opts = label_opts
  end

  def dsfr_champ_container
    :div
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
      opts[:data] = { controller: 'email-input', email_input_url_value: show_email_suggestions_path }
    end
    opts
  end

  def label_class_names
    class_names(
      'fr-label': true,
      'fr-password__label': password?,
      @label_opts[:class] => @label_opts[:class].present?
    )
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
    get_slot(:label).presence || default_label
  end

  def dsfr_input_classname
    'fr-input'
  end

  # kind of input helpers
  def password?
    @input_type == :password_field
  end

  def password_confirmation?
    attribute == :password_confirmation
  end

  def email?
    @input_type == :email_field
  end

  def autoresize?
    @input_type == :text_area && @autoresize
  end

  def required?
    @required
  end

  def show_password_id
    dom_id(object, "#{@attribute}_show_password")
  end

  private

  def default_label
    object.class.human_attribute_name(@attribute)
  end
end
