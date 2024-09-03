# frozen_string_literal: true

namespace :after_party do
  desc 'Deployment task: backfill_virus_scan_blobs'
  task backfill_virus_scan_blobs: :environment do
    puts "Running deploy task 'backfill_virus_scan_blobs'"

    pending_blobs = ActiveStorage::Blob.where("metadata like '%\"virus_scan_result\":\"#{ActiveStorage::VirusScanner::PENDING}%'").where(virus_scan_result: nil)
    infected_blobs = ActiveStorage::Blob.where("metadata like '%\"virus_scan_result\":\"#{ActiveStorage::VirusScanner::INFECTED}%'").where(virus_scan_result: nil)
    integrity_error_blobs = ActiveStorage::Blob.where("metadata like '%\"virus_scan_result\":\"#{ActiveStorage::VirusScanner::INTEGRITY_ERROR}%'").where(virus_scan_result: nil)
    safe_blobs = ActiveStorage::Blob.where("metadata like '%\"virus_scan_result\":\"#{ActiveStorage::VirusScanner::SAFE}%'").where(virus_scan_result: nil)

    pp "pending blobs: #{pending_blobs.count}"
    pp "infected blobs: #{infected_blobs.count}"
    pp "with integrity error blobs: #{integrity_error_blobs.count}"

    pending_blobs.in_batches.update_all(virus_scan_result: ActiveStorage::VirusScanner::PENDING)
    infected_blobs.in_batches.update_all(virus_scan_result: ActiveStorage::VirusScanner::INFECTED)
    integrity_error_blobs.in_batches.update_all(virus_scan_result: ActiveStorage::VirusScanner::INTEGRITY_ERROR)

    safe_blobs_ids = safe_blobs.pluck(:id)
    progress = ProgressReport.new(safe_blobs_ids.size)
    safe_blobs_ids.in_groups_of(10_000) do |batch|
      Migrations::BackfillVirusScanBlobsJob.perform_later(batch.compact)
      progress.inc(batch.compact.size)
    end
    progress.finish

    # Update task as completed.  If you remove the line below, the task will
    # run with every deploy (or every time you call after_party:run).
    AfterParty::TaskRecord
      .create version: AfterParty::TaskRecorder.new(__FILE__).timestamp
  end
end
