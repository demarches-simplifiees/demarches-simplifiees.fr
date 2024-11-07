# frozen_string_literal: true

class RdvConnection < ApplicationRecord
  belongs_to :instructeur

  validates :access_token, presence: true
  validates :refresh_token, presence: true
  validates :expires_at, presence: true
end
