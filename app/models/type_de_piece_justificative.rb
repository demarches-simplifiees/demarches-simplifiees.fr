class TypeDePieceJustificative < ApplicationRecord
  has_many :pieces_justificatives, dependent: :destroy

  belongs_to :procedure

  validates :libelle, presence: true, allow_blank: false, allow_nil: false

  validates :lien_demarche, format: { with: URI.regexp }, allow_blank: true, allow_nil: true
  scope :ordered, -> { order(order_place: :asc) }
end
