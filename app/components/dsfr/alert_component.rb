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

  private

  def initialize(state:, title:, heading_level: 'h3')
    @state = state
    @title = title
    @block = block
    @heading_level = heading_level
  end

  attr_reader :state, :title, :block, :heading_level
end
