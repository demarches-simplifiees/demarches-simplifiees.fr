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
  has_and_belongs_to_many :procedures, -> { order(published_at: :desc) }, inverse_of: :zone

  def current_label
    labels.first.name
  end

  def label_at(date)
    label = labels.where('designated_on < ?', date)&.first || labels.last
    label.name
  end

  def available_at?(date)
    label_at(date) != 'Non attribué'
  end

  def self.available_at(date)
    Zone.all.filter { |zone| zone.available_at?(date) }.sort_by { |zone| zone.label_at(date) }
  end
end
