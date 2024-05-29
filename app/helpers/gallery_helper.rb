module GalleryHelper
  def displayable_pdf?(blob)
    blob.previewable? && blob.content_type.in?(AUTHORIZED_PDF_TYPES)
  end

  def displayable_image?(blob)
    blob.variable? && blob.content_type.in?(AUTHORIZED_IMAGE_TYPES)
  end

  def preview_url_for(attachment)
    attachment.preview(resize_to_limit: [400, 400]).processed.url
  end

  def variant_url_for(attachment)
    attachment.variant(resize_to_limit: [400, 400]).processed.url
  end

  def blob_url(attachment)
    attachment.blob.content_type.in?(RARE_IMAGE_TYPES) ? attachment.variant(resize_to_limit: [2000, 2000]).processed.url : attachment.blob.url
  end
end
