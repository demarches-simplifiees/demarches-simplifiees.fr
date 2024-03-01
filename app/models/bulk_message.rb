class BulkMessage < ApplicationRecord
  belongs_to :instructeur
  belongs_to :procedure
  has_and_belongs_to_many :groupe_instructeurs, -> { order(:label) }
end
