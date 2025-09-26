# frozen_string_literal: true

class DossierTree::ChampComponent < ApplicationComponent
  attr_reader :champ, :seen_at

  def initialize(champ:, seen_at:, profile:)
    @champ = champ
    @seen_at = seen_at
    @profile = profile
  end

  private

  def usager?
    @profile == 'usager'
  end

  def badge_updated_class
    class_names(
      'fr-badge fr-badge--sm': true,
      'fr-badge--new': updated_since_seen?
    )
  end

  def updated_at_after_deposer
    champ.updated_at if updated_since_depose?
  end

  def blank_key
    key = champ.required? ? ".blank" : ".blank_optional"
    key += "_attachment" if champ.piece_justificative_or_titre_identite?
    key
  end

  def updated_since_seen?
    seen_at.present? && champ.updated_at&.>(seen_at)
  end

  def updated_since_depose?
    champ.depose_at.present? && champ.updated_at&.>(champ.depose_at)
  end
end
