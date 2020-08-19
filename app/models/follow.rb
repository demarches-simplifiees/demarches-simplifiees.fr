# == Schema Information
#
# Table name: follows
#
#  id                          :integer          not null, primary key
#  annotations_privees_seen_at :datetime         not null
#  avis_seen_at                :datetime         not null
#  demande_seen_at             :datetime         not null
#  messagerie_seen_at          :datetime         not null
#  unfollowed_at               :datetime
#  created_at                  :datetime
#  updated_at                  :datetime
#  dossier_id                  :integer          not null
#  instructeur_id              :integer          not null
#
class Follow < ApplicationRecord
  belongs_to :instructeur
  belongs_to :dossier

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
