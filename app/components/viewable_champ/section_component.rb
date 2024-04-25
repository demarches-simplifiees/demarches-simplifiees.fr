class ViewableChamp::SectionComponent < ApplicationComponent
  include ApplicationHelper
  include TreeableConcern

  def initialize(nodes: nil, types_de_champ: nil, row_id: nil, demande_seen_at:, profile:, champs_by_stable_id_with_row:)
    @demande_seen_at, @profile, @row_id, @champs_by_stable_id_with_row = demande_seen_at, profile, row_id, champs_by_stable_id_with_row
    nodes ||= to_tree(types_de_champ:)
    @nodes = to_sections(nodes:)
  end

  def section_id
    @section_id ||= header_section ? dom_id(header_section, :content) : SecureRandom.uuid
  end

  def header_section
    maybe_header_section = @nodes.first
    if maybe_header_section.is_a?(TypeDeChamp) && maybe_header_section.header_section?
      champ_for_type_de_champ(maybe_header_section)
    end
  end

  def champs
    tail.filter_map { _1.is_a?(TypeDeChamp) ? champ_for_type_de_champ(_1) : nil }
  end

  def sections
    tail.filter { _1.is_a?(ViewableChamp::SectionComponent) }
  end

  def tail
    return @nodes if header_section.blank?
    _, *rest_of_champ = @nodes

    rest_of_champ
  end

  def reset_tag_for_depth
    return if !header_section

    "reset-h#{header_section.level + 1}"
  end

  def first_level?
    return if header_section.nil?

    header_section.level == 1
  end

  private

  def to_sections(nodes:)
    nodes.map { _1.is_a?(Array) ? ViewableChamp::SectionComponent.new(nodes: _1, demande_seen_at: @demande_seen_at, profile: @profile, champs_by_stable_id_with_row: @champs_by_stable_id_with_row) : _1 }
  end

  def champ_for_type_de_champ(type_de_champ)
    @champs_by_stable_id_with_row[[@row_id, type_de_champ.stable_id].compact]
  end
end
