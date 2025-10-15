# frozen_string_literal: true

class EditableChamp::SectionComponent < ApplicationComponent
  include ApplicationHelper

  attr_reader :header_section

  def initialize(header_section:)
    @header_section = header_section
  end

  def tag_for_depth
    "h#{header_section.level + 1}"
  end
end
