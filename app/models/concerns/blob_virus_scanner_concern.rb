module BlobVirusScannerConcern
  extend ActiveSupport::Concern

  included do
    before_create :set_pending
  end

  def virus_scanner
    ActiveStorage::VirusScanner.new(self)
  end

  def scan_for_virus_later
    VirusScannerJob.perform_later(self)
  end

  private

  def set_pending
    metadata[:virus_scan_result] ||= ActiveStorage::VirusScanner::PENDING
  end
end
