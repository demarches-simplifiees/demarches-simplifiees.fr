# frozen_string_literal: true

class Follow < ApplicationRecord
  belongs_to :instructeur, optional: false
  belongs_to :dossier, optional: false, touch: true

  validates :instructeur_id, uniqueness: { scope: [:dossier_id, :unfollowed_at] }

  before_create :set_default_date

  scope :active, -> { where(unfollowed_at: nil) }
  scope :inactive, -> { where.not(unfollowed_at: nil) }

  private

  def set_default_date
    self.demande_seen_at ||= Time.zone.now
    self.annotations_privees_seen_at ||= Time.zone.now
    self.avis_seen_at ||= Time.zone.now
    self.messagerie_seen_at ||= Time.zone.now
  end
end
