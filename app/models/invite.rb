class Invite < ApplicationRecord
  include EmailSanitizableConcern

  belongs_to :dossier
  belongs_to :user

  before_validation -> { sanitize_email(:email) }

  validates :email, presence: true
  validates :email, uniqueness: { scope: :dossier_id }

  validates :email, format: { with: Devise.email_regexp, message: "n'est pas valide" }, allow_nil: true
end
