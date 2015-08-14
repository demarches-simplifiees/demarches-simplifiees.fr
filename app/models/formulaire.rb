class Formulaire < ActiveRecord::Base
  has_many :types_piece_jointe
  belongs_to :evenement_vie
end
