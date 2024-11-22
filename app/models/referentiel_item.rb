class ReferentielItem < ApplicationRecord
  belongs_to :referentiel, optional: false
end
