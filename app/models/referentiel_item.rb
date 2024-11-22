# frozen_string_literal: true

class ReferentielItem < ApplicationRecord
  belongs_to :referentiel, optional: false
end
