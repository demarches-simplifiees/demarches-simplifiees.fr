class Individual < ApplicationRecord
  belongs_to :dossier

  validates :dossier_id, uniqueness: true
  validates :gender, presence: true, allow_nil: false, on: :update
  validates :nom, presence: true, allow_blank: false, allow_nil: false, on: :update
  validates :prenom, presence: true, allow_blank: false, allow_nil: false, on: :update

  GENDER_MALE = 'M.'
  GENDER_FEMALE = 'Mme'

  def self.create_from_france_connect(fc_information)
    create!(
      nom: fc_information.family_name,
      prenom: fc_information.given_name,
      gender: fc_information.gender == 'female' ? GENDER_FEMALE : GENDER_MALE
    )
  end
end
