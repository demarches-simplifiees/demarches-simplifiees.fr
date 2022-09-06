class Dsfr::ButtonComponent < ApplicationComponent
  private

  attr_reader :label, :url, :form, :html_options

  # Mimic link_to signature link_to, except when form keyword is given for a submit, or when rendering a collection of buttons.
  #
  # `fr-btn` class is always added.
  #
  # Examples of usage:
  #
  # A link as a button, with any html option:
  # Dsfr::ButtonComponent.new("My link", "http://example.com", class: "fr-btn--secondary", title: "Link title")
  #
  # With external: true option which appends target="_blank", rel="noopener noreferrer" to html options:
  # Dsfr::ButtonComponent.new("My link", "http://example.com", class: "fr-btn--lg fr-btn--mb-1w", external: true)
  #
  # A submit button for a given form, (accept also any html option):
  # Dsfr::ButtonComponent.new("My submit", form: $form-builder-instance)
  #
  # A collection of button rendered:
  # Dsfr::ButtonComponent.with_collection([
  #   { label: "My link 1", url: "http://example.com" },
  #   { label: "My link 2", url: "http://example2.com", class: "fr-btn--secondary" }
  # ])
  #
  def initialize(label = nil, url = nil, form: nil, external: nil, button: nil, **html_options)
    if button.present?
      assign_attributes(**button)
    else
      assign_attributes(label:, form:, url:, html_options:, external:)
    end
  end

  def assign_attributes(label: nil, url: nil, form: nil, html_options: {}, external: false)
    @label = label
    @url = url
    @form = form
    @external = external

    @html_options = build_all_html_options(html_options)
  end

  def build_all_html_options(input_html_options)
    class_names = Array(input_html_options.delete(:class)).push("fr-btn")

    external_attributes.merge(class: class_names.join(" "), **input_html_options)
  end

  def external_attributes
    return {} unless external?

    { target: "_blank", rel: "noopener noreferrer" }
  end

  def external?
    @external
  end
end
