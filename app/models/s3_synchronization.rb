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
    POOL_SIZE = 25

    def synchronize(under_rake, until_time)
      if Rails.configuration.active_storage.service == :local
        upload(:local, :s3, under_rake, until_time)
      else
        upload(:s3, :local, under_rake, until_time)
      end
      AdministrationMailer.s3_synchronization_report.deliver_now
    end

    def switch_synchronize
      if Rails.configuration.active_storage.service == :local
        upload(:s3, :local, false, nil)
      else
        upload(:local, :s3, false, nil)
      end
      AdministrationMailer.s3_synchronization_report.deliver_now
    end

    def upload(from, to, under_rake, until_time)
      ActiveStorage::Blob.service
      configs = Rails.configuration.active_storage.service_configurations
      from_service = ActiveStorage::Service.configure from, configs

      ActiveStorage::Blob.service = from_service

      S3Synchronization.all.count # load class before multi-threading

      progress = ProgressReport.new(blobs_to_upload(from).count) if under_rake
      pool = Concurrent::FixedThreadPool.new(POOL_SIZE)

      blobs_to_upload(from).find_each do |blob|
        pool.post do
          upload_blob_if_present(from_service, configs, to, progress, until_time, blob)
        end
      end
      pool.shutdown
      pool.wait_for_termination
      progress.finish if progress
     end

    private

    def blobs_to_upload(from_service)
      ActiveStorage::Blob.joins('left join s3_synchronizations on  s3_synchronizations.active_storage_blob_id = active_storage_blobs.id')
        .where(s3_synchronizations: { checked: [false, nil] })
    end

    def upload_blob_if_present(from_service, configs, to, progress, until_time, blob)
      return if until_time.present? && Time.zone.now > until_time
      if from_service.exist?(blob.key)
        blob.open do |file|
          upload_blob(blob, file, configs, to, progress)
        end
      else
        puts "\nFichier non présent à la source : #{blob.key}"
      end
    rescue => e
      puts "\nErreur inconnue #{blob.key} #{e} #{e.message}"
      e.backtrace.each { |line| puts line }
    end

    def upload_blob(blob, file, configs, to, progress, &block)
      if File.file?(file)
        to_service = ActiveStorage::Service.configure to, configs
        synchronization = S3Synchronization.find_or_create_by(target: to, active_storage_blob_id: blob.id)
        upload_and_verify(to_service, blob, file, synchronization)
        upload_and_verify(to_service, blob, file, synchronization) # second try
      end
      progress.inc if progress
    end

    def upload_and_verify(to_service, blob, file, synchronization)
      unless synchronization&.checked
        upload_file(to_service, blob, file)
        check_integrity(to_service, blob, synchronization)
      end
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

    def check_integrity(to_service, blob, synchronization)
      begin
        to_service.open blob.key, checksum: blob.checksum do |f|
        end
        synchronization.checked = true
        synchronization.save
      rescue => e
        puts "\nIntegrity error on #{blob.key} #{e} #{e.message} ==> force upload"
      end
    end
  end
end
