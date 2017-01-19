class TypeDePieceJustificative < ActiveRecord::Base
  has_many :pieces_justificatives, dependent: :destroy

  belongs_to :procedure

  validates :libelle, presence: true, allow_blank: false, allow_nil: false

  validates_format_of :lien_demarche, with: URI::regexp
end
