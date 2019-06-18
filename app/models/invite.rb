class Invite < ApplicationRecord
  include EmailSanitizableConcern

  belongs_to :dossier, -> { unscope(where: :hidden_at) }
  belongs_to :user

  before_validation -> { sanitize_email(:email) }

  validates :email, presence: true
  validates :email, uniqueness: { scope: :dossier_id }

  validates :email, format: { with: Devise.email_regexp, message: "n'est pas valide" }, allow_nil: true

  # #1619 When an administrateur deletes a `Procedure`, its `hidden_at` field, and
  # the `hidden_at` field of its `Dossier`s, get set, effectively removing the Procedure
  # and Dossier from their respective `default_scope`s.
  # Therefore, we also remove `Invite`s for such effectively deleted `Dossier`s
  # from their default scope.
  default_scope { joins(:dossier).where(dossiers: { hidden_at: nil }) }
end
