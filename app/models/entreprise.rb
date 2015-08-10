class Entreprise < ActiveRecord::Base
  belongs_to :dossier
  has_one :etablissement
end
