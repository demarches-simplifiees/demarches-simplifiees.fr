module BlobImageProcessorConcern
  def watermark_pending?
    watermark_required? && !watermark_done?
  end

  def watermark_done?
    watermarked_at.present?
  end

  def representation_required?
    attachments.any? { _1.record.class == Champs::TitreIdentiteChamp || _1.record.class == Champs::PieceJustificativeChamp }
  end

  private

  def watermark_required?
    attachments.any? { _1.record.class == Champs::TitreIdentiteChamp }
  end
end
