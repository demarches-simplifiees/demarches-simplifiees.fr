class TypeDePieceJustificative < ActiveRecord::Base
  has_many :pieces_justificatives
  belongs_to :procedure
end
