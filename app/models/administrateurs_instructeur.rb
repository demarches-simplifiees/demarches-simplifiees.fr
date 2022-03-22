# == Schema Information
#
# Table name: administrateurs_instructeurs
#
#  created_at        :datetime
#  updated_at        :datetime
#  administrateur_id :integer          not null
#  instructeur_id    :integer          not null
#
class AdministrateursInstructeur < ApplicationRecord
  belongs_to :administrateur
  belongs_to :instructeur
end
