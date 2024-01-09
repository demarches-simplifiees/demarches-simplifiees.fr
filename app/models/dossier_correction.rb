class DossierCorrection < ApplicationRecord
  belongs_to :dossier
  belongs_to :commentaire

  validates_associated :commentaire

  scope :pending, -> { where(resolved_at: nil) }

  enum reason: { incorrect: 'incorrect', incomplete: 'incomplete' }, _prefix: :dossier

  def resolved?
    resolved_at.present?
  end
end
