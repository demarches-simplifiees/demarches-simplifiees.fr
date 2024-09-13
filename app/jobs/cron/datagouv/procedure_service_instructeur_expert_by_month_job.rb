# frozen_string_literal: true

class Cron::Datagouv::ProcedureServiceInstructeurExpertByMonthJob < Cron::CronJob
  include DatagouvCronSchedulableConcern
  self.schedule_expression = "every month at 3:40"
  FILE_NAME = "procedure_service_instructeur_expert"
  HEADERS = ["mois", "procedure_id", "service_siret", "service_adresse", "nb_groupe_instructeur", "nb_instructeur", "nb_expert"]

  def perform(*args)
    GenerateOpenDataCsvService.save_csv_to_tmp(FILE_NAME, HEADERS, data) do |file|
      begin
        APIDatagouv::API.upload(file, :statistics_dataset)
      ensure
        FileUtils.rm(file)
      end
    end
  end

  def data
    # possible adjustment: procedure with at least 300 folders
    Procedure.publiee
      .where(estimated_dossiers_count: 300.., opendata: true)
      .left_joins([:service, :groupe_instructeurs, :instructeurs, :experts])
      .group('procedures.id, services.siret')
      .pluck(
        'procedures.id',
        'services.siret',
        Arel.sql('COUNT(DISTINCT groupe_instructeurs.id)'),
        Arel.sql('COUNT(DISTINCT instructeurs.id)'),
        Arel.sql('COUNT(DISTINCT experts.id)')
      )
  end
end
