# frozen_string_literal: true

class ProcedureLabel < ApplicationRecord
  belongs_to :procedure

  validates :name, :color, presence: true
end
