class Entreprise < ActiveRecord::Base

  belongs_to :dossier
  has_one :etablissement, dependent: :destroy
  has_one :rna_information, dependent: :destroy

  validates_presence_of :siren
  validates_uniqueness_of :dossier_id

  before_save :default_values

  def default_values
    self.raison_sociale ||= ''
  end
end
