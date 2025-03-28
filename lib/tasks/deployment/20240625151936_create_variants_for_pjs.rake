namespace :after_party do
  desc 'Deployment task: create_variants_for_pjs'
  task create_variants_for_pjs: :environment do
    puts "Running deploy task 'create_variants_for_pjs'"

    # Put your task implementation HERE.
    dossier_ids = Dossier
      .state_en_construction_ou_instruction
      .where(depose_at: 3.months.ago..)
      .pluck(:id)

    champ_ids = Champ
      .where(dossier_id: dossier_ids)
      .where(type: ["Champs::PieceJustificativeChamp", 'Champs::TitreIdentiteChamp'])
      .pluck(:id)

    attachments = ActiveStorage::Attachment
      .where(record_id: champ_ids)

    attachments.in_batches.each_record do |attachment|
      next unless attachment.variable?
      attachment.variant(resize_to_limit: [400, 400]).processed if attachment.variant(resize_to_limit: [400, 400]).key.nil?
      if attachment.blob.content_type.in?(RARE_IMAGE_TYPES) && attachment.variant(resize_to_limit: [2000, 2000]).key.nil?
        attachment.variant(resize_to_limit: [2000, 2000]).processed
      end
    rescue MiniMagick::Error
    end

    # Update task as completed.  If you remove the line below, the task will
    # run with every deploy (or every time you call after_party:run).
    AfterParty::TaskRecord
      .create version: AfterParty::TaskRecorder.new(__FILE__).timestamp
  end
end
