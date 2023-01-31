# == Schema Information
#
# Table name: avis
#
#  id                   :integer          not null, primary key
#  answer               :text
#  claimant_type        :string
#  confidentiel         :boolean          default(FALSE), not null
#  email                :string
#  introduction         :text
#  reminded_at          :datetime
#  revoked_at           :datetime
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  claimant_id          :integer          not null
#  dossier_id           :integer
#  experts_procedure_id :bigint
#
class Avis < ApplicationRecord
  include EmailSanitizableConcern

  belongs_to :dossier, inverse_of: :avis, touch: true, optional: false
  belongs_to :experts_procedure, optional: false
  belongs_to :claimant, polymorphic: true, optional: false

  has_one_attached :piece_justificative_file
  has_one_attached :introduction_file
  has_one :expert, through: :experts_procedure
  has_one :procedure, through: :experts_procedure

  has_many :targeted_user_links, as: :target_model, dependent: :destroy, inverse_of: :target_model

  FILE_MAX_SIZE = 20.megabytes
  validates :piece_justificative_file,
    content_type: AUTHORIZED_CONTENT_TYPES,
    size: { less_than: FILE_MAX_SIZE }

  validates :introduction_file,
    content_type: AUTHORIZED_CONTENT_TYPES,
    size: { less_than: FILE_MAX_SIZE }

  validates :email, format: { with: Devise.email_regexp, message: "n'est pas valide" }, allow_nil: true
  validates :claimant, presence: true
  validates :piece_justificative_file, size: { less_than: FILE_MAX_SIZE }
  validates :introduction_file, size: { less_than: FILE_MAX_SIZE }
  before_validation -> { sanitize_email(:email) }

  default_scope { joins(:dossier) }
  scope :with_answer, -> { where.not(answer: nil) }
  scope :without_answer, -> { where(answer: nil) }
  scope :for_dossier, -> (dossier_id) { where(dossier_id: dossier_id) }
  scope :by_latest, -> { order(updated_at: :desc) }
  scope :updated_since?, -> (date) { where('avis.updated_at > ?', date) }
  scope :termine_expired, -> { unscope(:joins).where(dossier: Dossier.termine_expired) }
  scope :en_construction_expired, -> { unscope(:joins).where(dossier: Dossier.en_construction_expired) }
  scope :not_hidden_by_administration, -> { where(dossiers: { hidden_by_administration_at: nil }) }
  scope :not_revoked, -> { where(revoked_at: nil) }
  # The form allows subtmitting avis requests to several emails at once,
  # hence this virtual attribute.
  attr_accessor :emails
  attr_accessor :invite_linked_dossiers

  def email_to_display
    expert&.email
  end

  def spreadsheet_columns
    [
      ['Dossier ID', dossier_id.to_s],
      ['Question / Introduction', :introduction],
      ['Réponse', :answer],
      ['Créé le', :created_at],
      ['Répondu le', :updated_at],
      ['Instructeur', claimant&.email],
      ['Expert', expert&.email]
    ]
  end

  def updated_recently?
    updated_at > 30.minutes.ago
  end

  def revoked?
    revoked_at.present?
  end

  def revivable_by?(reviver)
    revokable_by?(reviver)
  end

  def revokable_by?(revocator)
    revocator.dossiers.include?(dossier) || revocator == claimant
  end

  def revoke_by!(revocator)
    return false if !revokable_by?(revocator)

    if answer.present?
      update!(revoked_at: Time.zone.now)
    else
      destroy!
    end
  end
end
