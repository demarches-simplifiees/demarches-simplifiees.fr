# == Schema Information
#
# Table name: s3_synchronizations
#
#  id                     :bigint           not null, primary key
#  checked                :boolean
#  target                 :string
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  active_storage_blob_id :bigint
#
class S3Synchronization < ApplicationRecord
  scope :uploaded_stats, -> {
    joins('join active_storage_blobs on  s3_synchronizations.active_storage_blob_id = active_storage_blobs.id')
      .select('target, updated_at::date as date, count(updated_at) as count, sum(active_storage_blobs.byte_size) as size')
      .group('target, date')
      .order('date desc')
  }

  scope :checked_stats, -> { uploaded_stats.where('checked') }

  class << self
    POOL_SIZE = 10

    def synchronize(under_rake, until_time)
      if Rails.configuration.active_storage.service == :local
        upload(:local, :s3, under_rake, until_time)
      else
        upload(:s3, :local, under_rake, until_time)
      end
      AdministrationMailer.s3_synchronization_report.deliver_now
    end

    def uploaded(to, to_service, blob)
      synchronization = S3Synchronization.find_or_create_by(target: to, active_storage_blob_id: blob.id)
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

    def upload_blobs(msg, from, to, under_rake, until_time, &block)
      puts msg
      configs = Rails.configuration.active_storage.service_configurations
      from_service = ActiveStorage::Service.configure from, configs
      progress = ProgressReport.new(ActiveStorage::Blob.count) if under_rake
      pool = Concurrent::FixedThreadPool.new(POOL_SIZE)

      blob = ActiveStorage::Blob.first
      process_blob(blob, block, configs, from, from_service, to, progress, until_time) if blob.present?

      ActiveStorage::Blob.find_each do |blob|
        pool.post do
          process_blob(blob, block, configs, from, from_service, to, progress, until_time)
        end
      end
      pool.shutdown
      pool.wait_for_termination
      progress.finish if progress
    end

    def upload_file(to_service, blob, file)
      begin
        puts "\nUploading file #{blob.id}\t#{blob.key} #{blob.byte_size}"
        to_service.upload(blob.key, file, checksum: blob.checksum)
      rescue SystemExit, Interrupt
        puts "\nCanceling upload of #{blob.key}"
        to_service.delete blob.key
        raise
      end
    end

    def upload(from, to, under_rake, until_time)
      ActiveStorage::Blob.service
      configs = Rails.configuration.active_storage.service_configurations
      from_service = ActiveStorage::Service.configure from, configs

      ActiveStorage::Blob.service = from_service

      S3Synchronization.all.count # load class before multi-threading

      msg = "First step: files not uploaded yet. #{ActiveStorage::Blob.count} Blobs to go..."
      upload_blobs(msg, from, to, under_rake, until_time) do |_service_name, service, blob|
        service.exist?(blob.key)
      end

      msg = "Second step: check integrity of files. #{ActiveStorage::Blob.count} Blobs to go..."
      upload_blobs(msg, from, to, under_rake, until_time) do |service_name, service, blob|
        uploaded(service_name, service, blob)
      end
    end

    private

    def process_blob(blob, block, configs, from, from_service, to, progress, until_time)
      begin
        return if until_time.present? && Time.zone.now > until_time
        if from_service.exist?(blob.key)
          blob.open do |file|
            upload_blob(blob, file, configs, to, progress, &block)
          end
        else
          puts "\nFichier non présent sur #{from}: #{blob.key}"
        end
      rescue => e
        puts "\nErreur inconnue #{blob.key} #{e} #{e.message}"
        e.backtrace.each { |line| puts line }
      end
    end

    def upload_blob(blob, file, configs, to, progress, &block)
      if File.file?(file)
        service = ActiveStorage::Service.configure to, configs
        unless yield(to, service, blob) then
          upload_file(service, blob, file)
        end
      end
      progress.inc if progress
    end
  end
end
