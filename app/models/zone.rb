# == Schema Information
#
# Table name: zones
#
#  id         :bigint           not null, primary key
#  acronym    :string           not null
#  label      :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class Zone < ApplicationRecord
  validates :acronym, presence: true, uniqueness: true
  has_many :labels, -> { order(designated_on: :desc) }, class_name: 'ZoneLabel', inverse_of: :zone
  has_many :procedures, -> { order(published_at: :desc) }, inverse_of: :zone

  def label
    labels.first.name
  end

  def label_at(date)
    labels_a = labels.pluck(:designated_on, :name)
    labels_a.find(-> { labels_a[-1] }) do |designated_on, _|
      date >= designated_on
    end.at(1)
  end
end
