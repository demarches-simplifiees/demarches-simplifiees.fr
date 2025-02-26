# frozen_string_literal: true

class ReferentielItem < ApplicationRecord
  belongs_to :referentiel, optional: false

  def value(path)
    data&.dig('row', path)
  end
end
