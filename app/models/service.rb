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
  validates :organisme, presence: { message: 'doit être renseigné' }, allow_nil: false
  validates :siret, length: { is: 14, message: 'doit être une suite de 14 chiffres' }, allow_nil: true
  validates :type_organisme, presence: { message: 'doit être renseigné' }, allow_nil: false
  validates :email, presence: { message: 'doit être renseigné' }, allow_nil: false
  validates :telephone, presence: { message: 'doit être renseigné' }, allow_nil: false
  validates :horaires, presence: { message: 'doivent être renseignés' }, allow_nil: false
  validates :adresse, presence: { message: 'doit être renseignée' }, allow_nil: false
  validates :administrateur, presence: { message: 'doit être renseigné' }, allow_nil: false

  def clone_and_assign_to_administrateur(administrateur)
    service_cloned = self.dup
    service_cloned.administrateur = administrateur
    service_cloned
  end
end
