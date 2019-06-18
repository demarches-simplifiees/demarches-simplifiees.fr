class Follow < ApplicationRecord
  belongs_to :gestionnaire
  belongs_to :dossier, -> { unscope(where: :hidden_at) }

  validates :gestionnaire_id, uniqueness: { scope: [:dossier_id, :unfollowed_at] }

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
