# == Schema Information
#
# Table name: s3_synchronizations
#
#  id         :bigint           not null, primary key
#  checked    :boolean
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class S3Synchronization < ApplicationRecord
  scope :uploaded_stats, -> {
    joins('join active_storage_blobs on s3_synchronizations.id = active_storage_blobs.id')
      .select('updated_at::date as date, count(updated_at) as count, sum(active_storage_blobs.byte_size) as size')
      .group('date')
      .order('date desc')
  }

  scope :checked_stats, -> { uploaded_stats.where('checked') }

  class << self
    POOL_SIZE = 10

    def synchronize(until_time)
      upload(:local, :s3, until_time)
      AdministrationMailer.s3_synchronization_report.deliver_now
    end

    def uploaded(to_service, blob)
      synchronization = S3Synchronization.find_or_create_by(id: blob.id)
      return true if synchronization.checked

      return false unless to_service.exist?(blob.key)

      begin
        to_service.open blob.key, checksum: blob.checksum do |f|
        end
        synchronization.checked = true
        synchronization.save
        return true
      rescue => e
        puts "\nIntegrity error on #{blob.key} #{e} #{e.message} ==> force upload"
        return false
      end
    rescue => e
      puts "\nErreur inconnue #{blob.key} #{e} #{e.message}"
      e.backtrace.each { |line| puts line }
      false
    end

    def upload_blobs(msg, from, to, until_time, &block)
      rake_print msg
      configs = Rails.configuration.active_storage.service_configurations
      from_service = ActiveStorage::Service.configure from, configs
      progress = ProgressReport.new(ActiveStorage::Blob.count)
      pool = Concurrent::FixedThreadPool.new(POOL_SIZE)

      ActiveStorage::Blob.find_each do |blob|
        local_file = from_service.path_for blob.key
        pool.post do
          begin
            next if until_time.present? && Time.zone.now > until_time
            upload_blob(blob, local_file, configs, to, progress, &block)
          rescue => e
            puts "\nErreur inconnue #{blob.key} #{e} #{e.message}"
            e.backtrace.each { |line| puts line }
          end
        end
      end
      pool.shutdown
      pool.wait_for_termination
      progress.finish
    end

    def upload_file(to_service, blob, local_file)
      begin
        puts "\nUploading file #{blob.id}\t#{blob.key} #{blob.byte_size}"
        to_service.upload(blob.key, File.open(local_file), checksum: blob.checksum)
      rescue SystemExit, Interrupt
        puts "\nCanceling upload of #{blob.key}"
        to_service.delete blob.key
        raise
      end
    end

    def upload(from, to, until_time)
      ActiveStorage::Blob.service
      configs = Rails.configuration.active_storage.service_configurations
      from_service = ActiveStorage::Service.configure from, configs

      ActiveStorage::Blob.service = from_service

      S3Synchronization.all.count # load class

      msg = "First step: files not uploaded yet. #{ActiveStorage::Blob.count} Blobs to go..."
      upload_blobs(msg, from, to, until_time) do |service, blob|
        service.exist?(blob.key)
      end

      msg = "Second step: check integrity of files. #{ActiveStorage::Blob.count} Blobs to go..."
      upload_blobs(msg, from, to, until_time) do |service, blob|
        uploaded(service, blob)
      end
    end

    private

    def upload_blob(blob, local_file, configs, to, progress, &block)
      if File.file?(local_file)
        service = ActiveStorage::Service.configure to, configs
        unless yield(service, blob) then
          upload_file(service, blob, local_file)
        end
      end
      progress.inc
    end
  end
end
