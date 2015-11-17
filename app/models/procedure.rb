class Procedure < ActiveRecord::Base
  has_many :types_de_piece_justificative
  has_many :types_de_champ
  has_many :dossiers
  accepts_nested_attributes_for :types_de_champ,:reject_if => proc { |attributes| attributes['libelle'].blank? }, :allow_destroy => true

  belongs_to :administrateur

  validates :libelle, presence: true, allow_blank: false, allow_nil: false
  validates :description, presence: true, allow_blank: false, allow_nil: false

  def types_de_champ_ordered
    types_de_champ.order(:order_place)
  end
end
