class Individual < ApplicationRecord
  include SanitizeConcern

  belongs_to :dossier

  validates :dossier_id, uniqueness: true
  validates :gender, presence: true, allow_nil: false, on: :update
  validates :nom, presence: true, allow_blank: false, allow_nil: false, on: :update
  validates :prenom, presence: true, allow_blank: false, allow_nil: false, on: :update
  before_validation -> {
    sanitize_uppercase(:nom)
    sanitize_camelcase(:prenom)
  }
end
