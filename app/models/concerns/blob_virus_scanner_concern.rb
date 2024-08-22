# frozen_string_literal: true

module BlobVirusScannerConcern
  extend ActiveSupport::Concern

  included do
    self.ignored_columns += [:lock_version]
    before_create :set_pending
  end

  def virus_scanner
    ActiveStorage::VirusScanner.new(self)
  end

  def scan_for_virus_later
    VirusScannerJob.perform_later(self)
  end

  def virus_scanner_error?
    return true if virus_scanner.infected?
    return true if virus_scanner.corrupt?

    false
  end

  private

  def set_pending
    self.virus_scan_result = metadata[:virus_scan_result] || ActiveStorage::VirusScanner::PENDING
  end
end
