class Follow < ApplicationRecord
  belongs_to :gestionnaire
  belongs_to :dossier

  validates :gestionnaire_id, uniqueness: { scope: :dossier_id }

  before_create :set_default_date

  private

  def set_default_date
    self.demande_seen_at ||= Time.zone.now
    self.annotations_privees_seen_at ||= Time.zone.now
    self.avis_seen_at ||= Time.zone.now
    self.messagerie_seen_at ||= Time.zone.now
  end
end
