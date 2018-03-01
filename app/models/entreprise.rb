class Entreprise < ActiveRecord::Base
  belongs_to :dossier
  has_one :etablissement, dependent: :destroy
  has_one :rna_information, dependent: :destroy

  validates_presence_of :siren
  validates_uniqueness_of :dossier_id

  accepts_nested_attributes_for :rna_information

  before_save :default_values

  def default_values
    self.raison_sociale ||= ''
  end

  attr_writer :mandataires_sociaux
end
