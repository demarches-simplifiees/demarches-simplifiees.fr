class Feedback < ApplicationRecord
  belongs_to :user

  enum rating: {
    happy:    'happy',
    neutral:  'neutral',
    unhappy:  'unhappy'
  }

  validates :rating, presence: true
end
