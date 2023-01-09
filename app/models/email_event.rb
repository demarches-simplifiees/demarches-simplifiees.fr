# == Schema Information
#
# Table name: email_events
#
#  id           :bigint           not null, primary key
#  method       :string           not null
#  processed_at :datetime
#  status       :string           not null
#  subject      :string           not null
#  to           :string           not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#
class EmailEvent < ApplicationRecord
  enum status: {
    dispatched: 'dispatched'
  }
end
