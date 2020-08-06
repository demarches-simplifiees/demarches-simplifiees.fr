class VirusScannerJob < ApplicationJob
  queue_as :active_storage_analysis

  discard_on ActiveRecord::RecordNotFound

  def perform(blob)
    metadata = extract_metadata_via_virus_scanner(blob)
    blob.update!(metadata: blob.metadata.merge(metadata))
  end

  def extract_metadata_via_virus_scanner(blob)
    ActiveStorage::VirusScanner.new(blob).metadata
  end
end
