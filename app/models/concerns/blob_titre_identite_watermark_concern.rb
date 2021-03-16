module BlobTitreIdentiteWatermarkConcern
  def watermark_pending?
    watermark_required? && !watermark_done?
  end

  def watermark_done?
    metadata[:watermark]
  end

  def watermark_later
    if watermark_required?
      TitreIdentiteWatermarkJob.perform_later(self)
    end
  end

  private

  def watermark_required?
    attachments.any? { |attachment| attachment.record.class.name == 'Champs::TitreIdentiteChamp' }
  end
end
