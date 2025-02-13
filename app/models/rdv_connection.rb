# frozen_string_literal: true

class RdvConnection < ApplicationRecord
  belongs_to :instructeur

  encrypts :access_token, :refresh_token

  validates :access_token, presence: true
  validates :refresh_token, presence: true
  validates :expires_at, presence: true

  def expired?
    expires_at && expires_at < Time.zone.now
  end
end
