class Procedure < ActiveRecord::Base
  has_many :types_de_piece_justificative
  has_many :types_de_champ
  has_many :dossiers
  accepts_nested_attributes_for :types_de_champ

  validates :libelle, presence: true, allow_blank: false, allow_nil: false
  validates :description, presence: true, allow_blank: false, allow_nil: false
end
