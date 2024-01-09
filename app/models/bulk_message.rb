class BulkMessage < ApplicationRecord
  belongs_to :instructeur
  has_and_belongs_to_many :groupe_instructeurs, -> { order(:label) }
  has_one_attached :piece_jointe
end
