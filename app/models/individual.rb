class Individual < ApplicationRecord
  belongs_to :dossier

  validates :dossier_id, uniqueness: true
  validates :gender, presence: true, allow_nil: false, on: :update
  validates :nom, presence: true, allow_blank: false, allow_nil: false, on: :update
  validates :prenom, presence: true, allow_blank: false, allow_nil: false, on: :update

  def birthdate
    second_birthdate
  end

  def birthdate=(date)
    self.second_birthdate = date
  end
end
