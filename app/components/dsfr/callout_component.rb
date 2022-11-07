# see: https://www.systeme-de-design.gouv.fr/elements-d-interface/composants/mise-en-avant
class Dsfr::CalloutComponent < ApplicationComponent
  renders_one :body
  renders_one :bottom

  attr_reader :title, :theme, :icon, :extra_class_names

  def initialize(title:, theme: :info, icon: nil, extra_class_names: nil)
    @title = title
    @theme = theme
    @icon = icon
    @extra_class_names = extra_class_names
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
    else
      # info is default theme
    end
  end
end
