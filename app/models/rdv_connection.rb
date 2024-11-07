# frozen_string_literal: true

class RdvConnection < ApplicationRecord
  belongs_to :instructeur, optional: true
  belongs_to :administrateur, optional: true

  validates :instructeur_id, presence: true, unless: -> { administrateur_id.present? }
  validates :administrateur_id, presence: true, unless: -> { instructeur_id.present? }
  validates :access_token, presence: true
  validates :refresh_token, presence: true
  validates :expiration, presence: true

  def instructeur_or_administrateur
    instructeur || administrateur
  end
end
