# frozen_string_literal: true

class ProcedurePath < ApplicationRecord
  belongs_to :procedure

  scope :activated, -> { where(deactivated_at: nil) }
  scope :deactivated, -> { where.not(deactivated_at: nil) }

  validates :path, presence: true, format: { with: /\A[a-z0-9_\-]{3,200}\z/ }, uniqueness: { scope: [:path, :deactivated_at], conditions: -> { where(deactivated_at: nil) }, case_sensitive: false }

  def activate!
    update!(activated: true)
  end
end
