# frozen_string_literal: true

module Maintenance
  class CreateVariantsForPjOfLatestDossiersTask < MaintenanceTasks::Task
    attribute :start_text, :string
    validates :start_text, presence: true

    attribute :end_text, :string
    validates :end_text, presence: true

    def collection
      start_date = DateTime.parse(start_text)
      end_date = DateTime.parse(end_text)

      Dossier
        .state_en_construction_ou_instruction
        .where(depose_at: start_date..end_date)
    end

    def process(dossier)
      champ_ids = Champ
        .where(dossier_id: dossier)
        .where(type: ["Champs::PieceJustificativeChamp", 'Champs::TitreIdentiteChamp'])
        .ids

      attachments = ActiveStorage::Attachment
        .where(record_id: champ_ids)

      attachments.each do |attachment|
        next if !(attachment.variable? && attachment.representation_required?)
        attachment.variant(resize_to_limit: [400, 400]).processed if attachment.variant(resize_to_limit: [400, 400]).key.nil?
        if attachment.blob.content_type.in?(RARE_IMAGE_TYPES) && attachment.variant(resize_to_limit: [2000, 2000]).key.nil?
          attachment.variant(resize_to_limit: [2000, 2000]).processed
        end
      rescue MiniMagick::Error
      end
    end
  end
end
