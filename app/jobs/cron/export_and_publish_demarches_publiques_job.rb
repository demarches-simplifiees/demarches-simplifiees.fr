class Cron::ExportAndPublishDemarchesPubliquesJob < Cron::CronJob
  self.schedule_expression = "every month at 3:00"

  def perform(*args)
    gzip_filepath = [
      ENV.fetch('DATAGOUV_TMP_DIR', 'tmp'), '/',
      Time.zone.now.to_formatted_s(:number),
      '-demarches.json.gz'
    ].join

    begin
      DemarchesPubliquesExportService.new(gzip_filepath).call
      APIDatagouv::API.upload(gzip_filepath)
    ensure
      FileUtils.rm(gzip_filepath)
    end
  end
end
