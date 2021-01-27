class Cron::FixMissingAntivirusAnalysis < Cron::CronJob
  self.schedule_expression = "every day at 2 am"

  def perform
    ActiveStorage::Blob.where("metadata like '%\"virus_scan_result\":\"pending%'").each do |b|
      begin
        VirusScannerJob.perform_now(b)
      rescue ActiveStorage::IntegrityError
      end
    end
  end
end
