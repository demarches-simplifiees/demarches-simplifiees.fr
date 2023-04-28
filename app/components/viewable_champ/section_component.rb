class ViewableChamp::SectionComponent < ApplicationComponent
  include ApplicationHelper
  include TreeableConcern

  def initialize(champs: nil, nodes: nil, demande_seen_at:, profile:)
    @demande_seen_at, @profile, @repetition = demande_seen_at, profile
    if nodes.nil?
      nodes = to_tree(champs:)
    end
    @nodes = to_sections(nodes:)
  end

  def section_id
    @section_id ||= header_section ? dom_id(header_section, :content) : SecureRandom.uuid
  end

  def header_section
    return @nodes.first if @nodes.first.is_a?(Champs::HeaderSectionChamp)
  end

  def champs
    tail.filter { _1.is_a?(Champ) && _1.visible? && !_1.exclude_from_view? }
  end

  def sections
    tail.filter { !_1.is_a?(Champ) }
  end

  def tail
    return @nodes if header_section.blank?
    _, *rest_of_champ = @nodes

    rest_of_champ
  end

  def tag_for_depth
    "h#{header_section.level + 1}" if header_section
  end

  private

  def to_sections(nodes:)
    nodes.map { _1.is_a?(Array) ? ViewableChamp::SectionComponent.new(nodes: _1, demande_seen_at: @demande_seen_at, profile: @profile) : _1 }
  end
end
