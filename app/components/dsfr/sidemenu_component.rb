class Dsfr::SidemenuComponent < ApplicationComponent
  renders_many :links, "LinkComponent"

  class LinkComponent < ApplicationComponent
    attr_reader :name, :url
    def initialize(name:, url:)
      @name = name
      @url = url
    end
  end

  def active?(url)
    current_page?(url)
  end
end
