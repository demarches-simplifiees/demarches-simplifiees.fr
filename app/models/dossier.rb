class Dossier < ActiveRecord::Base
  has_one :etablissement
  has_one :entreprise
  has_one :dossier_pdf
  has_many :commentaires
end
