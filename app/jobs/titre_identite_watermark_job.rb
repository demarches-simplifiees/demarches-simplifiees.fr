class TitreIdentiteWatermarkJob < ApplicationJob
  class FileNotScannedYetError < StandardError
  end

  # If by the time the job runs the blob has been deleted, ignore the error
  discard_on ActiveRecord::RecordNotFound
  # If the file is deleted during the scan, ignore the error
  discard_on ActiveStorage::FileNotFoundError
  # If the file is not analyzed or scanned for viruses yet, retry later
  # (to avoid modifying the file while it is being scanned).
  retry_on FileNotScannedYetError, wait: :exponentially_longer, attempts: 10

  def perform(blob)
    return if blob.watermark_done?
    raise FileNotScannedYetError if blob.virus_scanner.pending?

    blob.open do |file|
      processed = WatermarkService.new.process(file)

      return if processed.blank?

      blob.upload(processed)
      blob.touch(:watermarked_at)
    end
  end
end
