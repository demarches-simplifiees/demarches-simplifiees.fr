class AntiVirusJob < ApplicationJob
  include ActiveStorage::Downloading

  attr_reader :blob

  def perform(virus_scan)
    @blob = ActiveStorage::Blob.find_by(key: virus_scan.blob_key)

    if @blob.present?
      download_blob_to_tempfile do |file|
        if ClamavService.safe_file?(file.path)
          status = VirusScan.statuses.fetch(:safe)
        else
          status = VirusScan.statuses.fetch(:infected)
        end
        virus_scan.update(scanned_at: Time.zone.now, status: status)
      end
    end
  end
end
