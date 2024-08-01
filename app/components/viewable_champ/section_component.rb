# frozen_string_literal: true

class ViewableChamp::SectionComponent < ApplicationComponent
  include ApplicationHelper
  include TreeableConcern

  def initialize(dossier:, nodes: nil, types_de_champ: nil, row_id: nil, demande_seen_at:, profile:)
    @dossier, @demande_seen_at, @profile, @row_id = dossier, demande_seen_at, profile, row_id
    nodes ||= to_tree(types_de_champ:)
    @nodes = to_sections(nodes:)
  end

  private

  def section_id
    @section_id ||= header_section ? dom_id(header_section, :content) : SecureRandom.uuid
  end

  def header_section
    node = @nodes.first
    @dossier.project_champ(node, @row_id) if node.is_a?(TypeDeChamp) && node.header_section?
  end

  def champs
    tail.filter_map { _1.is_a?(TypeDeChamp) ? @dossier.project_champ(_1, @row_id) : nil }
  end

  def sections
    tail.filter { _1.is_a?(ViewableChamp::SectionComponent) }
  end

  def tail
    return @nodes if header_section.nil?
    _, *rest_of_champ = @nodes

    rest_of_champ
  end

  def reset_tag_for_depth
    return if header_section.nil?

    "reset-h#{header_section.level + 1}"
  end

  def first_level?
    return if header_section.nil?

    header_section.level == 1
  end

  private

  def to_sections(nodes:)
    nodes.map { _1.is_a?(Array) ? ViewableChamp::SectionComponent.new(dossier: @dossier, nodes: _1, demande_seen_at: @demande_seen_at, profile: @profile, row_id: @row_id) : _1 }
  end
end
