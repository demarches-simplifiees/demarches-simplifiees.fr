# frozen_string_literal: true

module Maintenance
  class CreatePreviewsForPjOfLatestDossiersTask < MaintenanceTasks::Task
    def collection
      dossier_ids = Dossier
        .state_en_construction_ou_instruction
        .where(depose_at: 3.months.ago..)
        .pluck(:id)

      champ_ids = Champ
        .where(dossier_id: dossier_ids)
        .where(type: ["Champs::PieceJustificativeChamp", 'Champs::TitreIdentiteChamp'])
        .pluck(:id)

      ActiveStorage::Attachment
        .where(record_id: champ_ids)
    end

    def process(attachment)
      return unless attachment.previewable?
      attachment.preview(resize_to_limit: [400, 400]).processed unless attachment.preview(resize_to_limit: [400, 400]).image.attached?
    rescue MiniMagick::Error
    end
  end
end
