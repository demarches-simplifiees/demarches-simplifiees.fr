class TypeDePieceJustificative < ActiveRecord::Base
  has_many :pieces_justificatives
  belongs_to :procedure

  validates :libelle, presence: true, allow_blank: false, allow_nil: false
end
