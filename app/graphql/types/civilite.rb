# frozen_string_literal: true

module Types
  class Civilite < Types::BaseEnum
    value("M", "Monsieur", value: Individual::GENDER_MALE)
    value("Mme", "Madame", value: Individual::GENDER_FEMALE)
  end
end
