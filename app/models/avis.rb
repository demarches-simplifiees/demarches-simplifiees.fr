class Avis < ApplicationRecord
  belongs_to :dossier, touch: true
  belongs_to :gestionnaire
  belongs_to :claimant, class_name: 'Gestionnaire'

  before_save :clean_email
  before_create :try_to_assign_gestionnaire
  after_create :notify_gestionnaire

  default_scope { joins(:dossier) }
  scope :with_answer, -> { where.not(answer: nil) }
  scope :without_answer, -> { where(answer: nil) }
  scope :for_dossier, ->(dossier_id) { where(dossier_id: dossier_id) }
  scope :by_latest, -> { order(updated_at: :desc) }

  def email_to_display
    gestionnaire.try(:email) || email
  end

  def self.link_avis_to_gestionnaire(gestionnaire)
    Avis.where(email: gestionnaire.email).update_all(email: nil, gestionnaire_id: gestionnaire.id)
  end

  def self.avis_exists_and_email_belongs_to_avis?(avis_id, email)
    avis = Avis.find_by(id: avis_id)
    avis.present? && avis.email == email
  end

  private

  def clean_email
    if email.present?
      self.email = email.downcase.strip
    end
  end

  def notify_gestionnaire
    AvisMailer.avis_invitation(self).deliver_now
  end

  def try_to_assign_gestionnaire
    gestionnaire = Gestionnaire.find_by(email: email)
    if gestionnaire
      self.gestionnaire = gestionnaire
      self.email = nil
    end
  end
end
