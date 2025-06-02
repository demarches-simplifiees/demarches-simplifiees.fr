# frozen_string_literal: true

# see: https://www.systeme-de-design.gouv.fr/elements-d-interface/composants/mise-en-avant
class Dsfr::CalloutComponent < ApplicationComponent
  renders_one :body
  renders_one :html_body
  renders_one :bottom

  attr_reader :title, :theme, :icon, :extra_class_names, :heading_level

  def initialize(title:, theme: :info, icon: nil, extra_class_names: nil, heading_level: 'h3')
    @title = title
    @theme = theme
    @icon = icon
    @extra_class_names = extra_class_names
    @heading_level = heading_level
  end

  def callout_class
    ["fr-callout", theme_class, icon, extra_class_names].compact.flatten
  end

  private

  def theme_class
    case theme
    when :warning
      "fr-callout--brown-caramel"
    when :success
      "fr-callout--green-emeraude"
    when :neutral
      # default
    else
      "fr-background-alt--blue-france"
    end
  end
end
