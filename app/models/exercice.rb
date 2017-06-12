class Exercice < ActiveRecord::Base
  belongs_to :etablissement

  validates :ca, presence: true, allow_blank: false, allow_nil: false
end
