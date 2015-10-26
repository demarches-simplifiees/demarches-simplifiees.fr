class Procedure < ActiveRecord::Base
  has_many :types_de_piece_justificative
  has_many :types_de_champs
  has_many :dossiers
  belongs_to :evenement_vie

  validates :libelle, presence: true, allow_blank: false, allow_nil: false
  validates :description, presence: true, allow_blank: false, allow_nil: false
  #validates :lien_demarche, presence: true, allow_blank: false, allow_nil: false
end
