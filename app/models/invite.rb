class Invite < ApplicationRecord
  belongs_to :dossier
  belongs_to :user

  validates :email, presence: true
  validates :email, uniqueness: { scope: :dossier_id }

  validates :email, email_format: true
end
