namespace :after_party do
  desc 'Deployment task: migrate_virus_scans'
  task migrate_virus_scans: :environment do
    puts "Running deploy task 'migrate_virus_scans'"

    virus_scans = VirusScan.all
    progress = ProgressReport.new(virus_scans.count)
    virus_scans.find_each do |virus_scan|
      blob = ActiveStorage::Blob.find_by(key: virus_scan.blob_key)
      if blob
        metadata = { virus_scan_result: virus_scan.status, scanned_at: virus_scan.scanned_at }
        blob.update_column(:metadata, blob.metadata.merge(metadata))
      end
      progress.inc
    end
    progress.finish

    # Update task as completed.  If you remove the line below, the task will
    # run with every deploy (or every time you call after_party:run).
    AfterParty::TaskRecord.create version: '20190425102459'
  end
end
