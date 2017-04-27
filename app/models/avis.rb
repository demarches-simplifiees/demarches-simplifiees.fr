class Avis < ApplicationRecord
  belongs_to :dossier
  belongs_to :gestionnaire

  scope :with_answer, -> { where.not(answer: nil) }
  scope :without_answer, -> { where(answer: nil) }

  def email_to_display
    gestionnaire.try(:email) || email
  end
end
