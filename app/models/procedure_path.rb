# frozen_string_literal: true

class ProcedurePath < ApplicationRecord
  belongs_to :procedure

  validates :path, presence: true, format: { with: /\A[a-z0-9_\-]{3,200}\z/ }, uniqueness: true
end
