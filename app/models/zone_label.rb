# == Schema Information
#
# Table name: zone_labels
#
#  id            :bigint           not null, primary key
#  designated_on :date             not null
#  name          :string           not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  zone_id       :bigint           not null
#
class ZoneLabel < ApplicationRecord
  belongs_to :zone
end
