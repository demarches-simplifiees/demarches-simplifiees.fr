class GroupeInstructeur < ApplicationRecord
  DEFAULT_LABEL = 'défaut'
  belongs_to :procedure
  has_many :assign_tos
  has_many :instructeurs, through: :assign_tos
end
