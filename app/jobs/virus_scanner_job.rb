class VirusScannerJob < ApplicationJob
  # If by the time the job runs the blob has been deleted, ignore the error
  discard_on ActiveRecord::RecordNotFound
  # If the file is deleted during the scan, ignore the error
  discard_on ActiveStorage::FileNotFoundError
  # If for some reason the file appears invalid, retry for a while
  retry_on(ActiveStorage::IntegrityError, attempts: 5, wait: 5.seconds) do |job, _error|
    blob = job.arguments.first

    metadata = {
      virus_scan_result: ActiveStorage::VirusScanner::INTEGRITY_ERROR,
      scanned_at: Time.zone.now
    }

    merge_and_update_metadata(blob, metadata)
  end

  def perform(blob)
    if blob.virus_scanner.done? then return end

    metadata = extract_metadata_via_virus_scanner(blob)

    VirusScannerJob.merge_and_update_metadata(blob, metadata)
  end

  def extract_metadata_via_virus_scanner(blob)
    ActiveStorage::VirusScanner.new(blob).metadata
  end

  private

  def self.merge_and_update_metadata(blob, metadata)
    blob.update!(metadata: blob.metadata.merge(metadata))
  end
end
