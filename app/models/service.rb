class Service < ApplicationRecord
  has_many :procedures
  belongs_to :administrateur

  scope :ordered, -> { order(nom: :asc) }

  enum type_organisme: {
    administration_centrale: 'administration_centrale',
    association: 'association',
    commune: 'commune',
    departement: 'departement',
    etablissement_enseignement: 'etablissement_enseignement',
    prefecture: 'prefecture',
    region: 'region',
    autre: 'autre'
  }

  validates :nom, presence: { message: 'doit être renseigné' }, allow_nil: false
  validates :nom, uniqueness: { scope: :administrateur, message: 'existe déjà' }
  validates :type_organisme, presence: { message: 'doit être renseigné' }, allow_nil: false
  validates :administrateur, presence: { message: 'doit être renseigné' }, allow_nil: false
end
