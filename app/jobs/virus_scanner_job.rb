class VirusScannerJob < ApplicationJob
  queue_as :active_storage_analysis

  # If by the time the job runs the blob has been deleted, ignore the error
  discard_on ActiveRecord::RecordNotFound
  # If the file is deleted during the scan, ignore the error
  discard_on ActiveStorage::FileNotFoundError

  # If for some reason the file appears invalid, retry for a while
  retry_on ActiveStorage::IntegrityError, attempts: 10, wait: 5.seconds

  def perform(blob)
    metadata = extract_metadata_via_virus_scanner(blob)
    blob.update!(metadata: blob.metadata.merge(metadata))
  end

  def extract_metadata_via_virus_scanner(blob)
    ActiveStorage::VirusScanner.new(blob).metadata
  end
end
