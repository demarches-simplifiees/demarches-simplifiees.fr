class Entreprise < ActiveRecord::Base
  belongs_to :dossier
  has_one :etablissement
  has_one :rna_information
end
