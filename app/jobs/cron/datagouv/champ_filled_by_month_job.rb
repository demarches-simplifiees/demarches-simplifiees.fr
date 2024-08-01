class Cron::Datagouv::ChampFilledByMonthJob < Cron::CronJob
  include DatagouvCronSchedulableConcern
  self.schedule_expression = "every month at 3:10"
  FILE_NAME = "nb_champs_remplis_par_mois"
  HEADERS = ["mois", "procedure_id", "type_de_champ_id", "type_champ", "libelle", "nb_champs_remplis"]

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
    # possible adjustment: procedure with at least 20 folders
    revisions =
      ProcedureRevision.joins(:procedure)
        .where(id: Procedure.select(:published_revision_id).where(estimated_dossiers_count: 20.., opendata: true))
        .includes(:types_de_champ)

    data = []

    revisions.map do |revision|
      champs =
        Champ.joins(:dossier)
          .where(dossier_id: Dossier.where(revision_id: revision, depose_at: 1.month.ago.all_month))

      revision.types_de_champ.where(private: false).map do |type_de_champ|
        nb =
          champs
            .where(stable_id: type_de_champ.stable_id)
            .where.not(value: [nil, ''])
            .count

        data << [revision.procedure_id, type_de_champ.stable_id, type_de_champ.type_champ, type_de_champ.libelle, nb]
      end
    end

    data.sort_by! { |procedure_id, _| procedure_id }
  end
end
