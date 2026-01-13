# frozen_string_literal: true

module Dsfr
  class AccordionComponent < ApplicationComponent
    renders_one :title

    attr_reader :id, :expanded, :title_tag

    def initialize(id: nil, expanded: false, title_tag: :h3)
      @id = id || generate_id
      @expanded = expanded
      @title_tag = title_tag
    end

    private

    def generate_id
      "accordion-#{SecureRandom.hex(4)}"
    end
  end
end
