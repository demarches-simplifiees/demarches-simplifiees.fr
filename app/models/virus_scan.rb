class VirusScan < ApplicationRecord
  belongs_to :champ

  enum status: {
    pending: 'pending',
    safe: 'safe',
    infected: 'infected'
  }

  validates :champ_id, uniqueness: { scope: :blob_key }

  after_create :perform_scan

  def perform_scan
    AntiVirusJob.perform_later(self)
  end
end
