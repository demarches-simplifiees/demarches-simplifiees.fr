class Formulaire < ActiveRecord::Base
  has_many :types_piece_jointe
  has_many :dossiers
  belongs_to :evenement_vie
end
