def uploaded(to_service, blob)
  uploaded = to_service.exist?(blob.key)
  if uploaded
    begin
      to_service.open blob.key, checksum: blob.checksum do |f|
      end
    rescue => e
      puts "Integrity error on #{blob.key} #{e} #{e.message}"
      uploaded = false
    end
  end
  uploaded
end

namespace :s3 do
  desc 'synchronize local storage to s3'
  task sync: :environment do
    puts "Synchronizing local storage files to s3"

    def migrate(from, to)
      ActiveStorage::Blob.service
      configs = Rails.configuration.active_storage.service_configurations
      from_service = ActiveStorage::Service.configure from, configs
      to_service = ActiveStorage::Service.configure to, configs

      ActiveStorage::Blob.service = from_service

      puts "#{ActiveStorage::Blob.count} Blobs to go..."
      progress = ProgressReport.new(ActiveStorage::Blob.count)
      ActiveStorage::Blob.find_each do |blob|
        # We assume the primary storage is local
        local_file = from_service.path_for blob.key
        if File.file?(local_file)
          unless uploaded(to_service, blob) then
            begin
              puts "Uploading file #{blob.key} #{blob.byte_size}"
              to_service.upload(blob.key, File.open(local_file), checksum: blob.checksum)
            rescue SystemExit, Interrupt
              puts "Canceling upload of #{blob.key}"
              to_service.delete blob.key
              raise
            end
          end
        end
        progress.inc
      end
      progress.finish
    end

    migrate(:local, :s3)

  end
end
