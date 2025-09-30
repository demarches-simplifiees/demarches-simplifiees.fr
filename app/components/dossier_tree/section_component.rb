# frozen_string_literal: true

class DossierTree::SectionComponent < ApplicationComponent
  attr_reader :children, :section, :seen_at, :profile

  def initialize(children:, section: nil, seen_at: nil, profile:)
    @section = section
    @children = children.filter { !_1.explication? && _1.visible? }
    @seen_at = seen_at
    @profile = profile
  end

  private

  def section? = section.present?
  def level = section.level + 1 # The first title level should be a <h2>
  def first_level? = section&.level == 1

  def section_id
    @section_id ||= section? ? dom_id(section, :content) : SecureRandom.uuid
  end

  def section_header_class
    class_names(
      {
        "section-#{level}": true,
        'header-section': auto_numbering?,
        'fr-m-0 fr-text--md fr-px-4v flex-grow': true,
        'fr-text-action-high--blue-france fr-py-2w': first_level?,
        'fr-py-1v': !first_level?
      }
    )
  end

  def auto_numbering?
    true
    # section.tree.sections.none? { _1.libelle =~ /^\d/ }
  end

  def reset_tag_for_depth
    return unless section?

    "reset-h#{level}"
  end

  def tag_for_depth
    if level <= 6
      "h#{level}"
    else
      "p"
    end
  end
end
