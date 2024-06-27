namespace :after_party do
  desc 'Deployment task: create_previews_for_pjs_from_messagerie'
  task create_previews_for_pjs_from_messagerie: :environment do
    puts "Running deploy task 'create_previews_for_pjs_from_messagerie'"

    # Put your task implementation HERE.
    dossier_ids = Dossier
      .state_en_construction_ou_instruction
      .where(depose_at: 3.months.ago..)
      .pluck(:id)

    commentaire_ids = Commentaire
      .where(dossier_id: dossier_ids)
      .pluck(:id)

    attachments = ActiveStorage::Attachment
      .where(record_id: commentaire_ids)

    attachments.in_batches.each_record do |attachment|
      next unless attachment.previewable?
      attachment.preview(resize_to_limit: [400, 400]).processed unless attachment.preview(resize_to_limit: [400, 400]).image.attached?
    rescue MiniMagick::Error
    end

    # Update task as completed.  If you remove the line below, the task will
    # run with every deploy (or every time you call after_party:run).
    AfterParty::TaskRecord
      .create version: AfterParty::TaskRecorder.new(__FILE__).timestamp
  end
end
