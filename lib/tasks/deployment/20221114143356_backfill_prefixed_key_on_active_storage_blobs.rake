namespace :after_party do
  desc 'Deployment task: backfill_migrated_on_active_storage_blobs'
  task backfill_prefixed_key_on_active_storage_blobs: :environment do
    puts "Running deploy task 'backfill_prefixed_key_on_active_storage_blobs'"

    if ENV['OBJECT_STORAGE_BLOB_PREFIXED_KEY'].present?
      blobs_to_migrate = ActiveStorage::Blob.where(prefixed_key: nil)
      progress = ProgressReport.new(blobs_to_migrate.count)
      blobs_to_migrate.find_each do |blob|
        blob.migrate_to_prefixed_key
        progress.inc
      end
      progress.finish
    end

    AfterParty::TaskRecord
      .create version: AfterParty::TaskRecorder.new(__FILE__).timestamp
  end
end
