class Individual < ActiveRecord::Base
  belongs_to :dossier

  validates_uniqueness_of :dossier_id

  validates :nom, presence: true, allow_nil: false, allow_blank: false
  validates :prenom, presence: true, allow_nil: false, allow_blank: false
  validates :birthdate, presence: true, allow_nil: false, allow_blank: false
end
