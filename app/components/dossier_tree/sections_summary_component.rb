# frozen_string_literal: true

class DossierTree::SectionsSummaryComponent < ApplicationComponent
  attr_reader :sections

  def initialize(tree:, revision: nil)
    @revision = revision
    @sections = tree.flatten.filter { ((_1.section? && !_1.row?) || _1.repeater?) && _1.visible? }
  end

  def render? = sections.any?

  def href(section)
    anchor = if @revision.present?
      ActionView::RecordIdentifier.dom_id(section.coordinate(@revision), :type_de_champ_editor)
    else
      dom_id(section)
    end
    "##{anchor}"
  end
end
