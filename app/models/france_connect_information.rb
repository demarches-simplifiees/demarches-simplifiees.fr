class FranceConnectInformation < ActiveRecord::Base
  belongs_to :user

  validates :france_connect_particulier_id, presence: true, allow_blank: false, allow_nil: false

  def self.find_by_france_connect_particulier user_info
    FranceConnectInformation.find_by(france_connect_particulier_id: user_info[:france_connect_particulier_id])
  end
end
