class VirusScan < ApplicationRecord
  belongs_to :champ

  enum status: {
    pending: 'pending',
    safe: 'safe',
    infected: 'infected'
  }
end
