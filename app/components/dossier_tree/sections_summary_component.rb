# frozen_string_literal: true

class DossierTree::SectionsSummaryComponent < ApplicationComponent
  attr_reader :sections

  def initialize(tree:)
    @sections = tree.flatten.filter { (_1.section? || _1.repeater?) && _1.visible? }
  end

  def render? = sections.any?

  def href(section) # used by viewable champs to anchor elements
    "##{section.html_id}"
  end
end
