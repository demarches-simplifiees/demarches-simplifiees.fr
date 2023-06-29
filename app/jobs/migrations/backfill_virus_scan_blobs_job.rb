class Migrations::BackfillVirusScanBlobsJob < ApplicationJob
  def perform(batch)
    ActiveStorage::Blob.where(id: batch)
      .update_all(virus_scan_result: ActiveStorage::VirusScanner::SAFE)
  end
end
