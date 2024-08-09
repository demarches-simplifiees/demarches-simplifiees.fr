class Cron::Datagouv::FileStateByMonthJob < Cron::CronJob
  include DatagouvCronSchedulableConcern
  self.schedule_expression = "every month at 3:20"
  FILE_NAME = "nb_dossiers_par_etat_par_mois"
  HEADERS = ["mois", "procedure_id", "nb_dossiers_crees", "nb_dossiers_deposes", "nb_dossiers_en_instruction", "nb_dossiers_traites"]

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
      .joins('INNER JOIN procedure_revisions ON procedures.published_revision_id = procedure_revisions.id')
      .joins('INNER JOIN dossiers ON procedure_revisions.id = dossiers.revision_id')
      .merge(Dossier.visible_by_user_or_administration)
      .order('procedures.id')
      .group('procedures.id')
      .pluck(
        'procedures.id',
        Arel.sql('SUM(CASE WHEN dossiers.state = \'brouillon\' THEN 1 ELSE 0 END)'),
        Arel.sql('SUM(CASE WHEN dossiers.state = \'en_construction\' THEN 1 ELSE 0 END)'),
        Arel.sql('SUM(CASE WHEN dossiers.state = \'en_instruction\' THEN 1 ELSE 0 END)'),
        Arel.sql('SUM(CASE WHEN dossiers.state IN (\'accepte\', \'sans_suite\', \'refuse\') THEN 1 ELSE 0 END)')
      )
  end
end
