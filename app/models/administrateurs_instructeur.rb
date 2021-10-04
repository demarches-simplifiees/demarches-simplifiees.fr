# == Schema Information
#
# Table name: administrateurs_instructeurs
#
#  created_at        :datetime
#  updated_at        :datetime
#  administrateur_id :integer
#  instructeur_id    :integer
#
class AdministrateursInstructeur < ApplicationRecord
  belongs_to :administrateur
  belongs_to :instructeur
end
