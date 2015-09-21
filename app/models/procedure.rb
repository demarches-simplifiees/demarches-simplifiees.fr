class Procedure < ActiveRecord::Base
  has_many :types_de_piece_justificative
  has_many :dossiers
  belongs_to :evenement_vie
end
