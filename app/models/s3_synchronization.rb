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

    def reset
      S3Synchronization.delete_all
      ActiveRecord::Base.connection.reset_pk_sequence!(:S3Synchronisations)
    end

    def synchronize(under_rake, until_time)
      if ['1', '2', '3'].include?(ENV.fetch('OUTSCALE_STEP', ''))
        upload(:local, :s3, under_rake, until_time)
      end
      if ['-1', '3'].include?(ENV.fetch('OUTSCALE_STEP', ''))
        upload(:s3, :local, under_rake, until_time)
      end
      AdministrationMailer.s3_synchronization_report.deliver_now if transfer_has_occured
    end

    def transfer_has_occured
      S3Synchronization.where('updated_at > ?', 1.minute.ago).count > 0
    end

    def switch_service(from_service, to_service)
      if blobs_to_switch(from_service).any?
        blobs_to_switch(from_service).update_all(service_name: to_service)
        AdministrationMailer.s3_synchronization_report.deliver_now
      end
    end

    def upload(from, to, under_rake, until_time)
      puts "Synchronizing from #{from} to #{to}#{until_time ? ' until ' + until_time.to_s : ''}"
      ActiveStorage::Blob.service
      configs = Rails.configuration.active_storage.service_configurations
      from_service = ActiveStorage::Service.configure from, configs

      ActiveStorage::Blob.service = from_service

      progress = ProgressReport.new(blobs_to_upload(from).count) if under_rake
      pool = Concurrent::FixedThreadPool.new(POOL_SIZE)

      blobs_to_upload(from).find_each do |blob|
        pool.post { upload_blob_if_present(from_service, configs, to, progress, until_time, blob) }
      end
      blobs_to_verify(from).find_each do |blob|
        pool.post { download_and_verify(configs, to, progress, until_time, blob) }
      end
      pool.shutdown
      pool.wait_for_termination
      progress.finish if progress
    end

    def blob_status
      {
        count: ActiveStorage::Blob.group(:service_name).count,
        sum: ActiveStorage::Blob.group(:service_name).sum(:byte_size)
      }
    end

    private

    def blobs_to_upload(from_service)
      blobs(from_service, [false, nil])
    end

    def blobs_to_verify(from_service)
      blobs((from_service.to_s + '_mirror').to_sym, [false, nil])
    end

    def blobs_to_switch(from_service)
      blobs(from_service, true)
    end

    def blobs(from_service, checked)
      ActiveStorage::Blob
        .joins('left join s3_synchronizations on  s3_synchronizations.active_storage_blob_id = active_storage_blobs.id')
        .where(s3_synchronizations: { checked: checked })
        .where(service_name: from_service)
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

    def download_and_verify(configs, to, progress, until_time, blob)
      return if until_time.present? && Time.zone.now > until_time
      to_service = ActiveStorage::Service.configure to, configs
      synchronization = S3Synchronization.find_or_create_by(target: to, active_storage_blob_id: blob.id)
      check_integrity(to_service, blob, synchronization)
      unless synchronization.checked
        blob.open do |file|
          upload_and_verify(to_service, blob, file, synchronization)
        end
      end
    rescue => e
      puts "\nErreur inconnue #{blob.key} #{e} #{e.message}"
      e.backtrace.each { |line| puts line }
    end

    def check_integrity(to_service, blob, synchronization)
      begin
        to_service.open blob.key, checksum: blob.checksum do |_f|
        end
        synchronization.checked = true
        synchronization.save
      rescue => e
        puts "\nIntegrity error on #{blob.key} #{e} #{e.message}"
      end
    end
  end
end
