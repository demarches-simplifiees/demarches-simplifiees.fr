class Traitement < ApplicationRecord
  belongs_to :dossier
  belongs_to :instructeur
end
