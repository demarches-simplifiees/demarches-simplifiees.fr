class Exercice < ApplicationRecord
  belongs_to :etablissement

  validates :ca, presence: true, allow_blank: false, allow_nil: false

  def date_fin_exercice
    super || dateFinExercice
  end
end
