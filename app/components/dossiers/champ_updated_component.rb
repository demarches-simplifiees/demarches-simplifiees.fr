# frozen_string_literal: true

class Dossiers::ChampUpdatedComponent < ApplicationComponent
  attr_reader :updated_at
  attr_reader :seen_at

  def initialize(updated_at: nil, seen_at: nil)
    @updated_at = updated_at
    @seen_at = seen_at
  end

  def badge_updated_class
    class_names(
      "fr-badge fr-badge--sm" => true,
      "fr-badge--new" => seen_at.present? && updated_at&.>(seen_at)
    )
  end

  def render?
    updated_at.present?
  end
end
