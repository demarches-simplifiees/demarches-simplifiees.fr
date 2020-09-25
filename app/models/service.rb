# == Schema Information
#
# Table name: services
#
#  id                :bigint           not null, primary key
#  adresse           :text
#  email             :string
#  horaires          :text
#  nom               :string           not null
#  organisme         :string
#  telephone         :string
#  type_organisme    :string           not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  administrateur_id :bigint
#
class Service < ApplicationRecord
  has_many :procedures
  belongs_to :administrateur, optional: false

  scope :ordered, -> { order(nom: :asc) }

  enum type_organisme: {
    administration_centrale: 'administration_centrale',
    association: 'association',
    collectivite_territoriale: 'collectivite_territoriale',
    etablissement_enseignement: 'etablissement_enseignement',
    operateur_d_etat: "operateur_d_etat",
    service_deconcentre_de_l_etat: 'service_deconcentre_de_l_etat',
    autre: 'autre'
  }

  validates :nom, presence: { message: 'doit être renseigné' }, allow_nil: false
  validates :nom, uniqueness: { scope: :administrateur, message: 'existe déjà' }
  validates :organisme, presence: { message: 'doit être renseigné' }, allow_nil: false
  validates :type_organisme, presence: { message: 'doit être renseigné' }, allow_nil: false
  validates :email, presence: { message: 'doit être renseigné' }, allow_nil: false
  validates :telephone, phone: { possible: true, allow_blank: true }
  validates :horaires, presence: { message: 'doivent être renseignés' }, allow_nil: false
  validates :adresse, presence: { message: 'doit être renseignée' }, allow_nil: false
  validates :administrateur, presence: { message: 'doit être renseigné' }, allow_nil: false

  def clone_and_assign_to_administrateur(administrateur)
    service_cloned = self.dup
    service_cloned.administrateur = administrateur
    service_cloned
  end

  def telephone_url
    if telephone.present?
      "tel:#{telephone.gsub(/[[:blank:]]/, '')}"
    end
  end

  PREPOSITIONS = Set['de', 'des', 'l', 'la', 'les', 'à', 'aux', 'le', 'et']

  def suggested_path
    # remove specialisation
    result = nom&.gsub(/\s*[-:].*/, "")
    # multiple words ==> remove prepositions and keep first letter of each word
    # one word ==> return the word
    result = result&.include?(' ') ? result.split(/[ ']+/).reject { |s| PREPOSITIONS.include?(s) }.map { |s| s[0] }.join() : result
    result&.parameterize
  end
end
