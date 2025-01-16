class Cron::FixMissingAntivirusAnalysisJob < Cron::CronJob
  self.schedule_expression = "every day at 01:45"

  def perform
    ActiveStorage::Blob.where(virus_scan_result: ActiveStorage::VirusScanner::PENDING).find_each do |blob|
      VirusScannerJob.perform_later(blob)
    end
  end
end
