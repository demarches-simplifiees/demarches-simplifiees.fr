# frozen_string_literal: true

class Referentiel < ApplicationRecord
  has_many :items, class_name: 'ReferentielItem', dependent: :destroy
  has_many :types_de_champ, inverse_of: :referentiel, dependent: :nullify
end
