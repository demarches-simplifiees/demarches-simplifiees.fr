# see: https://www.systeme-de-design.gouv.fr/elements-d-interface/composants/alerte
class Dsfr::AlertComponent < ApplicationComponent
  renders_one :body

  def prefix_for_state
    case state
    when :error then "Erreur : "
    when :info then "Information : "
    when :warning then "Attention : "
    when :success then ""
    else ""
    end
  end

  def alert_class(state)
    ["fr-alert fr-alert--#{state}", extra_class_names].compact.flatten
  end

  private

  def initialize(state:, title:, extra_class_names: nil, heading_level: 'h3')
    @state = state
    @title = title
    @block = block
    @extra_class_names = extra_class_names
    @heading_level = heading_level
  end

  attr_reader :state, :title, :block, :extra_class_names, :heading_level

  private
end
