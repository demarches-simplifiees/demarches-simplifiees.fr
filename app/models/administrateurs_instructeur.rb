# frozen_string_literal: true

class AdministrateursInstructeur < ApplicationRecord
  belongs_to :administrateur
  belongs_to :instructeur
end
