class Avis < ApplicationRecord
  belongs_to :dossier
  belongs_to :gestionnaire
  belongs_to :claimant, class_name: 'Gestionnaire'

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

  def self.link_avis_to_gestionnaire(gestionnaire)
    Avis.where(email: gestionnaire.email).update_all(email: nil, gestionnaire_id: gestionnaire.id)
  end

  def self.avis_exists_and_email_belongs_to_avis?(avis_id, email)
    avis = Avis.find_by(id: avis_id)
    avis.present? && avis.email == email
  end
end
