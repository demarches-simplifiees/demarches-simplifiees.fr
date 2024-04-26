class EditableChamp::SectionComponent < ApplicationComponent
  include ApplicationHelper
  include TreeableConcern

  def initialize(dossier:, nodes: nil, types_de_champ: nil, row_id: nil)
    nodes ||= to_tree(types_de_champ:)
    @dossier = dossier
    @row_id = row_id
    @nodes = to_fieldset(nodes:)
  end

  def render_within_fieldset?
    first_champ_is_an_header_section?
  end

  def header_section
    node = @nodes.first
    @dossier.project_champ(node, @row_id) if node.is_a?(TypeDeChamp) && node.header_section?
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
      [nil, @dossier.project_champ(node, @row_id)]
    end
  end

  private

  def to_fieldset(nodes:)
    nodes.map { _1.is_a?(Array) ? EditableChamp::SectionComponent.new(dossier: @dossier, nodes: _1, row_id: @row_id) : _1 }
  end

  def first_champ_is_an_header_section?
    header_section.present?
  end
end
