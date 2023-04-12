class EditableChamp::ChampsSubtreeComponent < ApplicationComponent
  include ApplicationHelper
  include TreeableConcern

  def initialize(nodes:)
    @nodes = to_fieldset(nodes:)
  end

  def render_within_fieldset?
    first_champ_is_an_header_section? && any_champ_fillable?
  end

  def header_section
    first_champ = @nodes.first
    return first_champ if first_champ.is_a?(Champs::HeaderSectionChamp)
    nil
  end

  def champs
    return @nodes if !first_champ_is_an_header_section?
    _, *rest_of_champ = @nodes

    rest_of_champ
  end

  def tag_for_depth
    "h#{header_section.level + 1}"
  end

  def fillable?
    false
  end

  private

  def to_fieldset(nodes:)
    nodes.map { _1.is_a?(Array) ? EditableChamp::ChampsSubtreeComponent.new(nodes: _1) : _1 }
  end

  def first_champ_is_an_header_section?
    header_section.present?
  end

  def any_champ_fillable?
    champs.any? { _1&.fillable? }
  end
end
