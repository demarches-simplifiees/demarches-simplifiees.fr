class AntiVirusJob < ApplicationJob
  include ActiveStorage::Downloading

  attr_reader :blob

  def perform(virus_scan)
    @blob = ActiveStorage::Blob.find_by(key: virus_scan.blob_key)

    if @blob.present?
      download_blob_to_tempfile do |file|
        if ClamavService.safe_file?(file.path)
          status = "safe"
        else
          status = "infected"
        end
        virus_scan.update(scanned_at: Time.now, status: status)
      end
    end
  end
end
