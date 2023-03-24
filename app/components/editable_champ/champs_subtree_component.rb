class EditableChamp::ChampsSubtreeComponent < ApplicationComponent
  include ApplicationHelper

  attr_reader :header_section, :nodes

  def initialize(header_section:)
    @header_section = header_section
    @nodes = []
  end

  # a nodes can be either a champs, or a subtree
  def add_node(node)
    nodes.push(node)
  end

  def render_within_fieldset?
    header_section && !empty_section?
  end

  def render_header_section_only?
    header_section && empty_section?
  end

  def empty_section?
    nodes.none? { |node| node.is_a?(Champ) }
  end

  def level
    if header_section.parent.present?
      header_section.header_section_level_value.to_i + header_section.parent.current_section_level
    elsif header_section
      header_section.header_section_level_value.to_i
    else
      0
    end
  end

  def tag_for_depth
    "h#{level + 1}"
  end
end
