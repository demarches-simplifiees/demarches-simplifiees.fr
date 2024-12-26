# frozen_string_literal: true

class Referentiels::CsvReferentiel < Referentiel
  has_many :items, class_name: 'ReferentielItem', dependent: :destroy
end
