class FranceConnectInformation < ActiveRecord::Base
  belongs_to :user

  validates :france_connect_particulier_id, presence: true, allow_blank: false, allow_nil: false
end
