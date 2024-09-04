# frozen_string_literal: true

class Cron::Datagouv::ProcedurePerLegalEntityByMonthJob < Cron::CronJob
  include DatagouvCronSchedulableConcern
  self.schedule_expression = "every month at 3:50"
  FILE_NAME = "procedure_effectuees_par_personne_morale_par_mois"
  HEADERS = ["mois", "siret", "procedure_id"]

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
    Etablissement
      .joins('INNER JOIN dossiers ON etablissements.dossier_id = dossiers.id')
      .merge(Dossier.visible_by_user_or_administration.where(depose_at: 1.month.ago.all_month))
      .joins('INNER JOIN procedures ON dossiers.revision_id = procedures.published_revision_id')
      .merge(Procedure.where(estimated_dossiers_count: 300.., opendata: true, for_individual: false))
      .order('procedures.id')
      .pluck('procedures.id', 'etablissements.siret', 'dossiers.depose_at')
  end
end
