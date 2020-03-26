require Rails.root.join("lib", "tasks", "task_helper")

namespace :after_party do
  desc 'Deployment task: synchronize_local_storage_to_minio'
  task sync_minio: :environment do
    puts "Running deploy task 'sync_minio'"

    def migrate(from, to)
      ActiveStorage::Blob.service
      configs = Rails.configuration.active_storage.service_configurations
      from_service = ActiveStorage::Service.configure from, configs
      to_service   = ActiveStorage::Service.configure to, configs

      ActiveStorage::Blob.service = from_service

      puts "#{ActiveStorage::Blob.count} Blobs to go..."
      progress = ProgressReport.new(ActiveStorage::Blob.count)
      ActiveStorage::Blob.find_each do |blob|
        # We assume the primary storage is local
        # local_file = from_service.path_for blob.key
        unless to_service.exist? blob.key then
          puts "Uploading file #{blob.key}"
          # to_service.upload(blob.key, File.open(local_file), checksum: blob.checksum)
        end
        progress.inc
      end
      progress.finish
    end

    migrate(:local, :minio)

    # Update task as completed.  If you remove the line below, the task will
    # run with every deploy (or every time you call after_party:run).
    # AfterParty::TaskRecord.create version: '20200326192442'
  end # task :sync_minio
end # namespace :after_party
