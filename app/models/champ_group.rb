class ChampGroup < ApplicationRecord
  delegate :libelle, :description, to: :parent

  belongs_to :parent, class_name: 'Champ'
  has_many :champs, foreign_key: :group_id, dependent: :destroy

  accepts_nested_attributes_for :champs, allow_destroy: true

  scope :ordered, -> { order(order_place: :asc) }
end
