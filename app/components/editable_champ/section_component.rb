class EditableChamp::SectionComponent < ApplicationComponent
  include ApplicationHelper
  include TreeableConcern

  def initialize(nodes: nil, champs: nil)
    nodes ||= to_tree(champs:)
    @nodes = to_fieldset(nodes:)
  end

  def render_within_fieldset?
    first_champ_is_an_header_section?
  end

  def container_attributes
    {
      class: class_names(
        "fr-my-0" => true,
        "hidden" => (header_section && !header_section.visible?)
      ),
      id: header_section&.input_group_id
    }
  end

  def header_section
    @nodes.first if @nodes.first.is_a?(Champs::HeaderSectionChamp)
  end

  def splitted_tail
    tail.map { split_section_champ(_1) }
  end

  def tail
    return @nodes if !first_champ_is_an_header_section?
    _, *rest_of_champ = @nodes

    rest_of_champ
  end

  def tag_for_depth
    "h#{header_section.level + 1}"
  end

  def split_section_champ(node)
    case node
    when EditableChamp::SectionComponent
      [node, nil]
    else
      [nil, node]
    end
  end

  private

  def to_fieldset(nodes:)
    nodes.map { _1.is_a?(Array) ? EditableChamp::SectionComponent.new(nodes: _1) : _1 }
  end

  def first_champ_is_an_header_section?
    header_section.present?
  end
end
