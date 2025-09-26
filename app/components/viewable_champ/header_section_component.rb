# frozen_string_literal: true

class ViewableChamp::HeaderSectionComponent < ApplicationComponent
  attr_reader :header_section

  def initialize(header_section:)
    @header_section = header_section
  end

  def reset_tag_for_depth
    "reset-h#{header_section.level + 1}"
  end

  def first_level?
    header_section.level == 1
  end

  def section_id = dom_id(header_section, :content)
end
