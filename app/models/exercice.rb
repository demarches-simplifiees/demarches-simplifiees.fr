# == Schema Information
#
# Table name: exercices
#
#  id                          :integer          not null, primary key
#  ca                          :string
#  dateFinExercice             :datetime
#  date_fin_exercice           :datetime
#  date_fin_exercice_timestamp :integer
#  created_at                  :datetime
#  updated_at                  :datetime
#  etablissement_id            :integer
#
class Exercice < ApplicationRecord
  belongs_to :etablissement

  validates :ca, presence: true, allow_blank: false, allow_nil: false
end
