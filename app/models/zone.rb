# frozen_string_literal: true

class Zone < ApplicationRecord
  validates :acronym, presence: true, uniqueness: true
  has_many :labels, -> { order(designated_on: :desc) }, class_name: 'ZoneLabel', inverse_of: :zone
  has_and_belongs_to_many :procedures, -> { order(published_at: :desc) }, inverse_of: :zone

  def current_label
    labels.where.not(name: 'Non attribué').first.name
  end

  def label_at(date)
    label = labels.where(designated_on: ...date)&.first || labels.last
    label.name
  end

  def available_at?(date)
    label_at(date) != 'Non attribué'
  end

  def self.available_at(date, without_zones = [])
    (Zone.all - without_zones).filter { |zone| zone.available_at?(date) }.sort_by { |zone| zone.label_at(date) }
      .map do |zone|
      LabelModel.new(id: zone.id, label: zone.label_at(date))
    end
  end

  def self.default_for(tchap_hs)
    sanitized_sql = ActiveRecord::Base.sanitize_sql "'#{tchap_hs}' = ANY (tchap_hs)"
    Zone.where(sanitized_sql)
  end
end
