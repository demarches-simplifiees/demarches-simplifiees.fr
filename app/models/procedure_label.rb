# frozen_string_literal: true

class ProcedureLabel < ApplicationRecord
  belongs_to :procedure

  GENERIC_LABELS = [
    { name: 'à relancer', color: 'brown-caramel' },
    { name: 'complet', color: 'green-bourgeon' },
    { name: 'prêt pour validation', color: 'green-archipel' }
  ]

  validates :name, :color, presence: true
end
