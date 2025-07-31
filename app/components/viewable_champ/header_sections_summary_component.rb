# frozen_string_literal: true

class ViewableChamp::HeaderSectionsSummaryComponent < ApplicationComponent
  attr_reader :sections

  def initialize(dossier:, is_private:, profile:)
    @dossier = dossier
    @is_private = is_private

    @sections = if is_private
      dossier.private_tree(profile:).sections
    else
      dossier.public_tree(profile:).sections
    end.filter(&:visible?)
  end

  def render? = sections.any?

  def href(section) # used by viewable champs to anchor elements
    "##{dom_id(section).gsub('section_', 'champ-')}"
  end
end
