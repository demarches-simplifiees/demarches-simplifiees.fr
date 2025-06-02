# frozen_string_literal: true

class VirusScannerJob < ApplicationJob
  # If by the time the job runs the blob has been deleted, ignore the error
  discard_on ActiveRecord::RecordNotFound
  # If the file is deleted during the scan, ignore the error
  discard_on ActiveStorage::FileNotFoundError
  # If for some reason the file appears invalid, retry for a while
  retry_on(ActiveStorage::IntegrityError, attempts: 5, wait: 5.seconds) do |job, _error|
    blob = job.arguments.first
    blob.update_columns(virus_scan_result: ActiveStorage::VirusScanner::INTEGRITY_ERROR, virus_scanned_at: Time.zone.now)
  end

  def perform(blob)
    return if blob.virus_scanner.done?

    blob.update_columns(ActiveStorage::VirusScanner.new(blob).attributes)
  end
end
