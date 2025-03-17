# frozen_string_literal: true

class Dsfr::SidemenuComponent < ApplicationComponent
  renders_many :links, "LinkComponent"

  class LinkComponent < ApplicationComponent
    attr_reader :name, :url, :icon
    def initialize(name:, url:, icon: nil)
      @name = name
      @url = url
      @icon = icon
    end
  end

  def active?(url)
    current_page?(url)
  end
end
