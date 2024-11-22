class Referentiel < ApplicationRecord
  has_many :items, class_name: 'ReferentielItem', dependent: :destroy
end
