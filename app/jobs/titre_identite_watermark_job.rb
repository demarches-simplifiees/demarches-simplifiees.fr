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

  MAX_IMAGE_SIZE = 1500
  SCALE = 0.9
  WATERMARK = URI.parse(WATERMARK_FILE).is_a?(URI::HTTP) ? WATERMARK_FILE : Rails.root.join("app/assets/images/#{WATERMARK_FILE}")

  def perform(blob)
    return if blob.watermark_done?
    raise FileNotScannedYetError if blob.virus_scanner.pending?

    blob.open do |file|
      watermark = resize_watermark(file)

      if watermark.present?
        processed = watermark_image(file, watermark)

        blob.upload(processed)
        blob.touch(:watermarked_at)
      end
    end
  end

  private

  def watermark_image(file, watermark)
    ImageProcessing::MiniMagick
      .source(file)
      .convert("png")
      .resize_to_limit(MAX_IMAGE_SIZE, MAX_IMAGE_SIZE)
      .composite(watermark, mode: "over", gravity: "center")
      .call
  end

  def resize_watermark(file)
    metadata = image_metadata(file)

    if metadata[:width].present? && metadata[:height].present?
      width = [metadata[:width], MAX_IMAGE_SIZE].min * SCALE
      height = [metadata[:height], MAX_IMAGE_SIZE].min * SCALE
      diagonal = Math.sqrt(height**2 + width**2)
      angle = Math.asin(height / diagonal) * 180 / Math::PI

      ImageProcessing::MiniMagick
        .source(WATERMARK)
        .resize_to_limit(diagonal, diagonal / 2)
        .rotate(-angle, background: :transparent)
        .call
    end
  end

  def image_metadata(file)
    read_image(file) do |image|
      if rotated_image?(image)
        { width: image.height, height: image.width }
      else
        { width: image.width, height: image.height }
      end
    end
  end

  def read_image(file)
    require "mini_magick"
    image = MiniMagick::Image.new(file.path)

    if image.valid?
      yield image
    else
      logger.info "Skipping image analysis because ImageMagick doesn't support the file"
      {}
    end
  end

  def rotated_image?(image)
    ['RightTop', 'LeftBottom'].include?(image["%[orientation]"])
  end
end
