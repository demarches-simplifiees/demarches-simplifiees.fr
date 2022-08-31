# see: https://www.systeme-de-design.gouv.fr/elements-d-interface/composants/mise-en-avant
class Dsfr::CalloutComponent < ApplicationComponent
  renders_one :body

  private

  def initialize(title:)
    @title = title
  end

  attr_reader :title
end
