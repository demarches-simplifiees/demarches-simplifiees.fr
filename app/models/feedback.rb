# == Schema Information
#
# Table name: feedbacks
#
#  id         :bigint           not null, primary key
#  rating     :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  user_id    :bigint
#
class Feedback < ApplicationRecord
  belongs_to :user

  enum rating: {
    happy:    'happy',
    neutral:  'neutral',
    unhappy:  'unhappy'
  }

  validates :rating, presence: true
end
