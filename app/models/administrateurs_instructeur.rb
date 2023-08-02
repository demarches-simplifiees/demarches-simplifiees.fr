class AdministrateursInstructeur < ApplicationRecord
  belongs_to :administrateur
  belongs_to :instructeur
end
