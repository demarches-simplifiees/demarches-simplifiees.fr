class VirusScannerJob < ApplicationJob
  def perform(blob)
    metadata = extract_metadata_via_virus_scanner(blob)
    if blob.metadata.present?
      blob.update!(metadata: blob.metadata.merge(metadata))
    else
      blob.update!(metadata: metadata)
    end
  end

  def extract_metadata_via_virus_scanner(blob)
    ActiveStorage::VirusScanner.new(blob).metadata
  end
end
