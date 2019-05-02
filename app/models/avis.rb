class Avis < ApplicationRecord
  include EmailSanitizableConcern

  belongs_to :dossier, touch: true
  belongs_to :gestionnaire
  belongs_to :claimant, class_name: 'Gestionnaire'

  has_one_attached :piece_justificative_file

  validates :email, format: { with: Devise.email_regexp, message: "n'est pas valide" }, allow_nil: true
  validates :claimant, presence: true

  before_validation -> { sanitize_email(:email) }
  before_create :try_to_assign_gestionnaire
  after_create :notify_gestionnaire

  default_scope { joins(:dossier) }
  scope :with_answer, -> { where.not(answer: nil) }
  scope :without_answer, -> { where(answer: nil) }
  scope :for_dossier, -> (dossier_id) { where(dossier_id: dossier_id) }
  scope :by_latest, -> { order(updated_at: :desc) }
  scope :updated_since?, -> (date) { where('avis.updated_at > ?', date) }

  # The form allows subtmitting avis requests to several emails at once,
  # hence this virtual attribute.
  attr_accessor :emails

  def email_to_display
    gestionnaire&.email || email
  end

  def self.link_avis_to_gestionnaire(gestionnaire)
    Avis.where(email: gestionnaire.email).update_all(email: nil, gestionnaire_id: gestionnaire.id)
  end

  def self.avis_exists_and_email_belongs_to_avis?(avis_id, email)
    Avis.find_by(id: avis_id)&.email == email
  end

  # FIXME remove this after migrating virus_scan to blob metadata
  def virus_scan
    VirusScan.find_by(blob_key: piece_justificative_file.blob.key)
  end

  def virus_scan_safe?
    virus_scan&.safe? || piece_justificative_file.virus_scanner.safe?
  end

  def virus_scan_infected?
    virus_scan&.infected? || piece_justificative_file.virus_scanner.infected?
  end

  def virus_scan_pending?
    virus_scan&.pending? || piece_justificative_file.virus_scanner.pending?
  end

  def virus_scan_no_scan?
    virus_scan.blank? && !piece_justificative_file.virus_scanner.analyzed?
  end

  private

  def notify_gestionnaire
    AvisMailer.avis_invitation(self).deliver_later
  end

  def try_to_assign_gestionnaire
    gestionnaire = Gestionnaire.find_by(email: email)
    if gestionnaire
      self.gestionnaire = gestionnaire
      self.email = nil
    end
  end
end
