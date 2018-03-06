class FranceConnectInformation < ApplicationRecord
  belongs_to :user

  validates :france_connect_particulier_id, presence: true, allow_blank: false, allow_nil: false

  def mandataire_social?(params)
    params[:nom].casecmp(family_name).zero? &&
      params[:prenom].casecmp(given_name).zero? &&
      params[:date_naissance_timestamp] == birthdate.to_time.to_i
  end
end
