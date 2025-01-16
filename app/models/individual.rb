# frozen_string_literal: true

class Individual < ApplicationRecord
  enum :notification_method, {
    email: 'email',
    no_notification: 'no_notification'
  }

  belongs_to :dossier, optional: false

  validates :dossier_id, uniqueness: true
  validates :gender, presence: true, allow_nil: false, on: :update
  validates :nom, presence: true, allow_blank: false, allow_nil: false, on: :update
  validates :prenom, presence: true, allow_blank: false, allow_nil: false, on: :update
  validates :notification_method, presence: true,
                                  inclusion: { in: notification_methods.keys },
                                  if: -> { dossier.for_tiers? },
                                  on: :update

  validates :email, strict_email: true, presence: true, if: -> { dossier.for_tiers? && self.email? }, on: :update
  validate :email_different_from_mandataire, on: :update

  after_commit -> { dossier.index_search_terms_later }, if: -> { nom_previously_changed? || prenom_previously_changed? }

  GENDER_MALE = "M."
  GENDER_FEMALE = 'Mme'

  def self.from_france_connect(fc_information)
    new(
      nom: fc_information.family_name,
      prenom: fc_information.given_name,
      gender: fc_information.gender == 'female' ? GENDER_FEMALE : GENDER_MALE
    )
  end

  def unverified_email? = !email_verified_at?

  def email_different_from_mandataire
    if email.present? && email.casecmp?(dossier.user.email)
      errors.add(:email, :must_be_different_from_mandataire)
    end
  end
end
