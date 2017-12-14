class Follow < ActiveRecord::Base
  belongs_to :gestionnaire
  belongs_to :dossier

  validates_uniqueness_of :gestionnaire_id, :scope => :dossier_id

  before_create :set_default_date

  private

  def set_default_date
    self.demande_seen_at ||= DateTime.now
    self.annotations_privees_seen_at ||= DateTime.now
    self.avis_seen_at ||= DateTime.now
    self.messagerie_seen_at ||= DateTime.now
  end
end
