class Cron::Datagouv::ExportAndPublishDemarchesPubliquesJob < Cron::CronJob
  self.schedule_expression = "every month at 3:00"

  def perform(*args)
    gzip_filepath = [
      'tmp/',
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

  def self.schedulable?
    ENV.fetch('OPENDATA_ENABLED', nil) == 'enabled'
  end
end
