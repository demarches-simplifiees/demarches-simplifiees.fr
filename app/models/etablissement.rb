class Etablissement < ActiveRecord::Base
  belongs_to :dossier
  belongs_to :entreprise
end
