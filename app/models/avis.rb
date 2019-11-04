class Avis < ApplicationRecord
  include EmailSanitizableConcern

  belongs_to :dossier, inverse_of: :avis, touch: true
  belongs_to :instructeur
  belongs_to :claimant, class_name: 'Instructeur'

  has_one_attached :piece_justificative_file

  validates :email, format: { with: Devise.email_regexp, message: "n'est pas valide" }, allow_nil: true
  validates :claimant, presence: true

  before_validation -> { sanitize_email(:email) }
  before_create :try_to_assign_instructeur

  default_scope { joins(:dossier) }
  scope :with_answer, -> { where.not(answer: nil) }
  scope :without_answer, -> { where(answer: nil) }
  scope :for_dossier, -> (dossier_id) { where(dossier_id: dossier_id) }
  scope :by_latest, -> { order(updated_at: :desc) }
  scope :updated_since?, -> (date) { where('avis.updated_at > ?', date) }

  # The form allows subtmitting avis requests to several emails at once,
  # hence this virtual attribute.
  attr_accessor :emails
  attr_accessor :invite_linked_dossiers

  def email_to_display
    instructeur&.email || email
  end

  def self.link_avis_to_instructeur(instructeur)
    Avis.where(email: instructeur.email).update_all(email: nil, instructeur_id: instructeur.id)
  end

  def self.avis_exists_and_email_belongs_to_avis?(avis_id, email)
    Avis.find_by(id: avis_id)&.email == email
  end

  def spreadsheet_columns
    [
      ['Dossier ID', dossier_id.to_s],
      ['Question / Introduction', :introduction],
      ['Réponse', :answer],
      ['Créé le', :created_at],
      ['Répondu le', :updated_at]
    ]
  end

  private

  def try_to_assign_instructeur
    instructeur = Instructeur.find_by(email: email)
    if instructeur
      self.instructeur = instructeur
      self.email = nil
    end
  end
end
