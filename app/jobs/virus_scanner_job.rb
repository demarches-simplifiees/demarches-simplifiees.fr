class VirusScannerJob < ApplicationJob
  class FileNotAnalyzedYetError < StandardError
  end

  queue_as :active_storage_analysis

  # If by the time the job runs the blob has been deleted, ignore the error
  discard_on ActiveRecord::RecordNotFound
  # If the file is deleted during the scan, ignore the error
  discard_on ActiveStorage::FileNotFoundError
  # If the file is not analyzed yet, retry later (to avoid clobbering metadata)
  retry_on FileNotAnalyzedYetError

  def perform(blob)
    raise FileNotAnalyzedYetError if !blob.analyzed?
    return if blob.virus_scanner.done?

    metadata = extract_metadata_via_virus_scanner(blob)
    blob.update!(metadata: blob.metadata.merge(metadata))
  end

  def extract_metadata_via_virus_scanner(blob)
    ActiveStorage::VirusScanner.new(blob).metadata
  end
end
