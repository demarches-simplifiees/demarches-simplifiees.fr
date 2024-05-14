# frozen_string_literal: true

class Exercice < ApplicationRecord
  belongs_to :etablissement, optional: false

  validates :ca, presence: true, allow_blank: false, allow_nil: false
end
