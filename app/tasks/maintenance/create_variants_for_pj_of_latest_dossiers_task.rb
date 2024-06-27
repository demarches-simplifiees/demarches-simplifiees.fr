# frozen_string_literal: true

module Maintenance
  class CreateVariantsForPjOfLatestDossiersTask < MaintenanceTasks::Task
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
      return unless attachment.variable?
      attachment.variant(resize_to_limit: [400, 400]).processed if attachment.variant(resize_to_limit: [400, 400]).key.nil?
      if attachment.blob.content_type.in?(RARE_IMAGE_TYPES) && attachment.variant(resize_to_limit: [2000, 2000]).key.nil?
        attachment.variant(resize_to_limit: [2000, 2000]).processed
      end
    rescue MiniMagick::Error
    end
  end
end
