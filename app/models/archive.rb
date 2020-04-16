class Archive < ApplicationRecord
  include AASM

  MAX_DUREE_CONSERVATION_ARCHIVE = 1.week

  belongs_to :instructeur
  belongs_to :procedure

  has_one_attached :file

  enum content_type: {
    everything: 'everything',
    monthly:    'monthly'
  }

  enum status: {
    pending: 'pending',
    generated: 'generated'
  }

  aasm whiny_persistence: true, column: :status, enum: true do
    state :pending, initial: true
    state :generated

    event :make_available do
      transitions from: :pending, to: :generated
    end
  end
end
