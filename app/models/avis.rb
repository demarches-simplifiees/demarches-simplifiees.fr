class Avis < ApplicationRecord
  belongs_to :dossier
  belongs_to :gestionnaire

  scope :with_answer, -> { where.not(answer: nil) }
  scope :without_answer, -> { where(answer: nil) }
  scope :by_latest, -> { order(updated_at: :desc) }

  def find_email
    gestionnaire.try(:email) || email
  end
end
