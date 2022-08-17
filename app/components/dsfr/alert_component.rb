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
  def initialize(state:, title:)
    @state = state
    @title = title
    @block = block
  end

  attr_reader :state, :title, :block

end
