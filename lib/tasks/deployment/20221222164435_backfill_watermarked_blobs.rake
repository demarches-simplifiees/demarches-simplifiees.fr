# frozen_string_literal: true

namespace :after_party do
  desc 'Deployment task: backfill_watermarked_blobs'
  task backfill_watermarked_blobs: :environment do
    puts "Running deploy task 'backfill_watermarked_blobs'"

    ActiveStorage::Blob.where("metadata like '%\"watermark\":true%'")
      .where(watermarked_at: nil)
      .in_batches
      .update_all('watermarked_at = created_at')

    # Update task as completed.  If you remove the line below, the task will
    # run with every deploy (or every time you call after_party:run).
    AfterParty::TaskRecord
      .create version: AfterParty::TaskRecorder.new(__FILE__).timestamp
  end
end
