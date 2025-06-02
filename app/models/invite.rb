# frozen_string_literal: true

class Invite < ApplicationRecord
  include EmailSanitizableConcern

  belongs_to :dossier, optional: false
  belongs_to :user, optional: true
  has_one :targeted_user_link, as: :target_model, dependent: :destroy, inverse_of: :target_model

  before_validation -> { sanitize_email(:email) }

  after_create_commit :send_notification

  validates :email, presence: true
  validates :email, uniqueness: { scope: :dossier_id }
  validates :email, strict_email: true, allow_nil: true

  scope :with_dossiers, -> { joins(:dossier).merge(Dossier.visible_by_user) }

  default_scope { with_dossiers }

  def send_notification
    if self.user.present?
      InviteMailer.invite_user(self).deliver_later
    else
      InviteMailer.invite_guest(self).deliver_later
    end
  end
end
