# == Schema Information
#
# Table name: zones
#
#  id         :bigint           not null, primary key
#  acronym    :string
#  label      :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class Zone < ApplicationRecord
  validates :acronym, presence: true, uniqueness: true
end
