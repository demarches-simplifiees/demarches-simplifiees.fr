module BlobTitreIdentiteWatermarkConcern
  def watermark_pending?
    watermark_required? && !watermark_done?
  end

  def watermark_done?
    watermarked_at.present?
  end

  def watermark_later
    if watermark_pending?
      TitreIdentiteWatermarkJob.perform_later(self)
    end
  end

  private

  def watermark_required?
    attachments.any? { _1.record.class == Champs::TitreIdentiteChamp }
  end
end
