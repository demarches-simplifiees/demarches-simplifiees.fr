class Avis < ApplicationRecord
  belongs_to :dossier
  belongs_to :gestionnaire

  after_create :notify_gestionnaire

  scope :with_answer, -> { where.not(answer: nil) }
  scope :without_answer, -> { where(answer: nil) }
  scope :for_dossier, ->(dossier_id) { where(dossier_id: dossier_id) }
  scope :by_latest, -> { order(updated_at: :desc) }

  def email_to_display
    gestionnaire.try(:email) || email
  end

  def notify_gestionnaire
    AvisMailer.you_are_invited_on_dossier(self).deliver_now
  end
end
