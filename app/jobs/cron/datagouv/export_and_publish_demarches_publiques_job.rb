# frozen_string_literal: true

class Cron::Datagouv::ExportAndPublishDemarchesPubliquesJob < Cron::CronJob
  include DatagouvCronSchedulableConcern
  self.schedule_expression = "every month at 4:10"

  def perform(*args)
    gzip_filepath = [
      'tmp/',
      Time.zone.now.to_fs(:number),
      '-demarches.json.gz'
    ].join

    begin
      DemarchesPubliquesExportService.new(gzip_filepath).call
      io = File.new(gzip_filepath, 'r')
      APIDatagouv::API.upload(io, :descriptif_demarches_dataset, :descriptif_demarches_resource)
    ensure
      FileUtils.rm(gzip_filepath)
    end
  end
end
