module BlobImageProcessorConcern
  def watermark_pending?
    watermark_required? && !watermark_done?
  end

  def watermark_done?
    watermarked_at.present?
  end

  def representation_required?
    from_champ? || from_messagerie?
  end

  private

  def from_champ?
    attachments.any? { _1.record.class == Champs::TitreIdentiteChamp || _1.record.class == Champs::PieceJustificativeChamp }
  end

  def from_messagerie?
    attachments.any? { _1.record.class == Commentaire }
  end

  def watermark_required?
    attachments.any? { _1.record.class == Champs::TitreIdentiteChamp }
  end
end
