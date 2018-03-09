class Entreprise < ApplicationRecord
  belongs_to :dossier
  has_one :etablissement
  has_one :rna_information, dependent: :destroy

  validates :siren, presence: true
  validates :dossier_id, uniqueness: true

  accepts_nested_attributes_for :rna_information, update_only: true

  before_save :default_values

  def default_values
    self.raison_sociale ||= ''
  end

  attr_writer :mandataires_sociaux
end
