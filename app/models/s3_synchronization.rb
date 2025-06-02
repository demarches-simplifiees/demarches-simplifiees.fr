# frozen_string_literal: true

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

    def perform_step(step, until_time)
      case step
      when '-1' # cancel
        upload(:s3, :local, false, until_time)
        S3Synchronization.switch_service(:s3, :local, until_time)
        S3Synchronization.switch_service(:s3_mirror, :local, until_time)
        S3Synchronization.switch_service(:local_mirror, :local, until_time)
      when '0' # init
        S3Synchronization.reset
      when '1', '2' # upload blobs
        upload(:local, :s3, false, until_time)
      when '3' # switch to s3_mirror : cancel possible
        S3Synchronization.switch_service(:local, :s3_mirror, until_time)
        S3Synchronization.switch_service(:local_mirror, :s3_mirror, until_time)
      when '4' # switch to s3, cancel not possible
        S3Synchronization.switch_service(:s3_mirror, :s3, until_time)
      when '5' # delete local file stored on s3
        S3Synchronization.move_mirrored_files(:s3, :local, until_time)
      else
      end
    end

    def transfer_has_occured
      S3Synchronization.where('updated_at > ?', 1.minute.ago).count > 0
    end

    def move_mirrored_files(main_service_name, mirror_service_name, until_time)
      configs = active_storage_configs
      mirror_service = ActiveStorage::Service.configure mirror_service_name, configs
      save_dir = Rails.root.join("storage/backup")
      count = 0
      not_deleted_count = 0
      blob_keys(main_service_name, until_time) do |key|
        f = Pathname(mirror_service.path_for(key))
        if File.exist?(f)
          count += 1
          move(key, f, save_dir)
        end
        not_deleted_count += 1 if File.exist?(f)
        dir = f.dirname
        dir.delete if dir.exist? && dir.empty?
        dir = dir.dirname
        dir.delete if dir.exist? && dir.empty?
      end
      msg = "Archived #{count} files from '#{mirror_service_name}' storage service.\n" +
        "Files not moved: #{not_deleted_count}"
      AdministrationMailer.s3_synchronization_report(msg).deliver_now
    end

    def move(key, filename, save_dir)
      to_dir = Pathname(save_dir) / key[0..1] / key[2..3]
      to_dir.mkpath
      FileUtils.move(filename.to_s, to_dir.to_s)
    end

    def switch_service(from_service, to_service, until_time)
      return if until_time.present? && Time.zone.now > until_time

      if blobs_to_switch(from_service).any?
        blobs_to_switch(from_service).in_batches do |relation|
          break if until_time.present? && Time.zone.now > until_time
          relation.update_all(service_name: to_service)
          sleep(2)
        end
        AdministrationMailer.s3_synchronization_report('').deliver_now
      end
    end

    def upload(from, to, under_rake, until_time)
      @logio = StringIO.new
      @logger = Logger.new @logio
      @logger.info "Synchronizing from #{from} to #{to}#{until_time ? ' until ' + until_time.to_s : ''}."
      configs = active_storage_configs
      from_service = ActiveStorage::Service.configure from, configs

      ActiveStorage::Blob.service = from_service

      progress = under_rake ? ProgressReport.new(blobs_to_upload(from).count) : nil
      pool = Concurrent::FixedThreadPool.new(POOL_SIZE)

      blobs_to_upload(from).find_each do |blob|
        break if until_time.present? && Time.zone.now > until_time
        enqueue(pool) { upload_blob_if_present(from_service, configs, to, progress, until_time, blob) }
      end
      blobs_to_verify(from).find_each do |blob|
        break if until_time.present? && Time.zone.now > until_time
        enqueue(pool) { download_and_verify(configs, to, progress, until_time, blob) }
      end
      pool.shutdown
      pool.wait_for_termination
      progress.finish if progress
      AdministrationMailer.s3_synchronization_report(@logio.string).deliver_now if transfer_has_occured
    end

    def blob_status
      {
        count: ActiveStorage::Blob.group(:service_name).count,
        sum: ActiveStorage::Blob.group(:service_name).sum(:byte_size)
      }
    end

    private

    def blob_keys(main_service_name, until_time)
      ActiveStorage::Blob.where(service_name: main_service_name).in_batches(of: 300) do |relation|
        break if until_time.present? && Time.zone.now > until_time
        relation.pluck(:key).each do |key|
          yield key
        end
      end
    end

    def active_storage_configs
      ActiveStorage::Blob.service
      Rails.configuration.active_storage.service_configurations
    end

    def enqueue(pool, &block)
      if pool.queue_length > 2 * POOL_SIZE
        yield
      else
        pool.post(&block)
      end
    end

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
      base = ActiveStorage::Blob.where(service_name: from_service)
      return base if from_service.to_s.ends_with?('mirror')

      base.joins('left join s3_synchronizations on  s3_synchronizations.active_storage_blob_id = active_storage_blobs.id')
        .where(s3_synchronizations: { checked: checked })
    end

    def upload_blob_if_present(from_service, configs, to, progress, until_time, blob)
      return if until_time.present? && Time.zone.now > until_time
      if from_service.exist?(blob.key)
        blob.open do |file|
          upload_blob(blob, file, configs, to, progress)
        end
      else
        @logger.info "Fichier non présent à la source : #{blob.key}"
      end
    rescue => e
      @logger.error "Erreur inconnue #{blob.key} #{e} #{e.message}"
      e.backtrace.each { |line| @logger.error line if /\/app\//.match?(line) }
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
        # @logger.info "Uploading file #{blob.id}\t#{blob.key} #{blob.byte_size}"
        to_service.upload(blob.key, file, checksum: blob.checksum)
      rescue SystemExit, Interrupt
        @logger.error "Canceling upload of #{blob.key}"
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
        @logger.info "Trying re uploading #{blob.key}"
        blob.open do |file|
          upload_and_verify(to_service, blob, file, synchronization)
        end
      end
    rescue => e
      @logger.error "Erreur inconnue #{blob.key}, #{e}, #{e.message}"
      e.backtrace.each { |line| @logger.error line if /\/app\//.match?(line) }
    end

    def check_integrity(to_service, blob, synchronization)
      begin
        to_service.open blob.key, checksum: blob.checksum do |_f|
        end
        synchronization.checked = true
        synchronization.save
      rescue => e
        @logger.error "Integrity error reading #{blob.key}, #{e}, #{e.message}"
      end
    end
  end
end
