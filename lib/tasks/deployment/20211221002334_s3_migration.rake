namespace :after_party do
  desc 'Deployment task: s3_migration'
  task s3_migration: :environment do
    def set_all_blob_service(service)
      # rubocop:disable DS/Unscoped
      blobs_to_update = ActiveStorage::Blob.unscoped.where.not(service_name: service)
      # rubocop:enable DS/Unscoped
      if blobs_to_update.count > 0
        puts 'Setting blob service. This could take a while…'
        blobs_to_update.update_all service_name: service
      end
    end

    puts "Running deploy task 's3_migration'"

    case ENV.fetch('OUTSCALE_STEP', "")
    when '-1'
      set_all_blob_service(:local)
    when '3'
      S3Synchronization.synchronize(true, Time.zone.now + 3.minutes)
      S3Synchronization.switch_service(:local, :s3_mirror)
      S3Synchronization.switch_service(:local_mirror, :s3_mirror)
    when '0'
      S3Synchronization.reset
    when '4'
      S3Synchronization.switch_service(:s3_mirror, :s3)
    else
    end

    # Update task as completed.  If you remove the line below, the task will
    # run with every deploy (or every time you call after_party:run).
    # AfterParty::TaskRecord
    #   .create version: AfterParty::TaskRecorder.new(__FILE__).timestamp
  end
end
