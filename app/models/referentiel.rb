class Referentiel < ApplicationRecord
  has_many :items, class_name: 'ReferentielItem', dependent: :destroy
  has_many :types_de_champ, inverse_of: :referentiel
end
