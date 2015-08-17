class TypePieceJointe < ActiveRecord::Base
  has_many :pieces_jointes
  belongs_to :formulaire
end
