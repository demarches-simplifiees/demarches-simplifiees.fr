# frozen_string_literal: true

module GalleryHelper
  def displayable_pdf?(blob)
    blob.previewable? && blob.content_type.in?(AUTHORIZED_PDF_TYPES)
  end

  def displayable_image?(blob)
    blob.variable? && blob.content_type.in?(AUTHORIZED_IMAGE_TYPES)
  end

  def preview_url_for(attachment)
    preview = attachment.preview(resize_to_limit: [400, 400])
    preview.image.attached? ? preview.processed.url : 'pdf-placeholder.png'
  rescue StandardError
    'pdf-placeholder.png'
  end

  def variant_url_for(attachment)
    variant = attachment.variant(resize_to_limit: [400, 400])
    variant.key.present? ? variant.processed.url : 'apercu-indisponible.png'
  rescue StandardError
    'apercu-indisponible.png'
  end

  def blob_url(attachment)
    variant = attachment.variant(resize_to_limit: [2000, 2000])
    attachment.blob.content_type.in?(RARE_IMAGE_TYPES) && variant.key.present? ? variant.processed.url : attachment.blob.url
  rescue StandardError
    attachment.blob.url
  end
end
