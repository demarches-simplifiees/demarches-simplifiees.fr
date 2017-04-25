class Avis < ApplicationRecord
  belongs_to :dossier
  belongs_to :gestionnaire
end
