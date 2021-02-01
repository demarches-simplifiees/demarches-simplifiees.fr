# == Schema Information
#
# Table name: individuals
#
#  id         :integer          not null, primary key
#  birthdate  :date
#  gender     :string
#  nom        :string
#  prenom     :string
#  created_at :datetime
#  updated_at :datetime
#  dossier_id :integer
#
class Individual < ApplicationRecord
  include SanitizeConcern

  belongs_to :dossier, optional: false

  validates :dossier_id, uniqueness: true
  validates :gender, presence: true, allow_nil: false, on: :update
  validates :nom, presence: true, allow_blank: false, allow_nil: false, on: :update
  validates :prenom, presence: true, allow_blank: false, allow_nil: false, on: :update
  before_validation -> {
    sanitize_uppercase(:nom)
    sanitize_camelcase(:prenom)
  }

  GENDER_MALE = "M."
  GENDER_FEMALE = 'Mme'

  def self.from_france_connect(fc_information)
    new(
      nom: fc_information.family_name,
      prenom: fc_information.given_name,
      gender: fc_information.gender == 'female' ? GENDER_FEMALE : GENDER_MALE
    )
  end
end
