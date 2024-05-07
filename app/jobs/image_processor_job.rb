class ImageProcessorJob < ApplicationJob
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
    return if blob.nil?
    raise FileNotScannedYetError if blob.virus_scanner.pending?
    return if ActiveStorage::Attachment.find_by(blob_id: blob.id)&.record_type == "ActiveStorage::VariantRecord"

    auto_rotate(blob) if ["image/jpeg", "image/jpg"].include?(blob.content_type)
    create_representations(blob) if blob.representation_required?
    add_watermark(blob) if blob.watermark_pending?
  end

  private

  def auto_rotate(blob)
    blob.open do |file|
      Tempfile.create(["rotated", File.extname(file)]) do |output|
        processed = AutoRotateService.new.process(file, output)
        return if processed.blank?

        blob.upload(processed) # also update checksum & byte_size accordingly
        blob.save!
      end
    end
  end

  def create_representations(blob)
    blob.attachments.each do |attachment|
      next unless attachment&.representable?
      attachment.representation(resize_to_limit: [400, 400]).processed
    end
  end

  def add_watermark(blob)
    return if blob.watermark_done?

    blob.open do |file|
      Tempfile.create(["watermarked", File.extname(file)]) do |output|
        processed = WatermarkService.new.process(file, output)
        return if processed.blank?

        blob.upload(processed) # also update checksum & byte_size accordingly
        blob.watermarked_at = Time.current
        blob.save!
      end
    end
  end
end
