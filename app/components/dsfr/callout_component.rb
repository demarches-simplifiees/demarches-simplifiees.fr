# see: https://www.systeme-de-design.gouv.fr/elements-d-interface/composants/mise-en-avant
class Dsfr::CalloutComponent < ApplicationComponent
  renders_one :body
  renders_one :bottom

  attr_reader :title, :theme, :icon

  def initialize(title:, theme: :info, icon: nil)
    @title = title
    @theme = theme
    @icon = icon
  end

  def callout_class
    ["fr-callout", theme_class, icon]
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
