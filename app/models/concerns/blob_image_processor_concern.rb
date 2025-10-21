# frozen_string_literal: true

module BlobImageProcessorConcern
  extend ActiveSupport::Concern

  included do
    def watermark_pending?
      watermark_required? && !watermark_done?
    end

    def watermark_done?
      watermarked_at.present?
    end

    def representation_required?
      from_champ? || from_messagerie? || logo? || from_action_text? || from_avis? || from_justificatif_motivation?
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

    def from_avis?
      attachments.any? { _1.record.class == Avis }
    end

    def watermark_required?
      attachments.any? { _1.record.class == Champs::TitreIdentiteChamp }
    end

    def from_justificatif_motivation?
      attachments.any? { _1.name == 'justificatif_motivation' }
    end
  end
end
