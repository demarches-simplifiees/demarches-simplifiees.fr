class VirusScannerJob < ApplicationJob
  class FileNotAnalyzedYetError < StandardError
  end

  queue_as :active_storage_analysis

  # If by the time the job runs the blob has been deleted, ignore the error
  discard_on ActiveRecord::RecordNotFound
  # If the file is deleted during the scan, ignore the error
  discard_on ActiveStorage::FileNotFoundError
  # If the file is not analyzed yet, retry later (to avoid clobbering metadata)
  retry_on FileNotAnalyzedYetError, wait: :exponentially_longer, attempts: 10
  # If for some reason the file appears invalid, retry for a while
  retry_on ActiveStorage::IntegrityError, attempts: 10, wait: 5.seconds

  def perform(blob)
    if !blob.analyzed? then raise FileNotAnalyzedYetError end
    if blob.virus_scanner.done? then return end

    metadata = extract_metadata_via_virus_scanner(blob)
    blob.update!(metadata: blob.metadata.merge(metadata))
  end

  def extract_metadata_via_virus_scanner(blob)
    ActiveStorage::VirusScanner.new(blob).metadata
  end
end
