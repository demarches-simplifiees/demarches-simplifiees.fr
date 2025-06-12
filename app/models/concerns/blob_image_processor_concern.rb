# frozen_string_literal: true

module BlobImageProcessorConcern
  def watermark_pending?
    watermark_required? && !watermark_done?
  end

  def watermark_done?
    watermarked_at.present?
  end

  def representation_required?
    from_champ? || from_messagerie? || logo? || from_action_text?
  end

  private

  def from_champ?
    attachments.any? { _1.record.class == Champs::TitreIdentiteChamp || _1.record.class == Champs::PieceJustificativeChamp }
  end

  def from_messagerie?
    attachments.any? { _1.record.class == Commentaire }
  end

  def logo?
    attachments.any? { _1.name == 'logo' }
  end

  def from_action_text?
    attachments.any? { _1.record.class == ActionText::RichText }
  end

  def watermark_required?
    attachments.any? { _1.record.class == Champs::TitreIdentiteChamp }
  end
end
