class Individual < ActiveRecord::Base
  belongs_to :dossier

  validates_uniqueness_of :dossier_id
  validates :birthdate, format: { with: /\A\d{4}\-\d{2}\-\d{2}\z/, message: "La date n'est pas au format AAAA-MM-JJ" }, allow_nil: true
end
