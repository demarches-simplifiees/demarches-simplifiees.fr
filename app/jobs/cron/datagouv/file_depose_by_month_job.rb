# frozen_string_literal: true

class Cron::Datagouv::FileDeposeByMonthJob < Cron::Datagouv::BaseJob
  self.schedule_expression = "every month at 5:00"
  HEADERS = ["mois", "nb_dossiers_deposes_par_mois"]
  FILE_NAME = HEADERS[1]
  RESOURCE = '26131021-33fd-4a37-9c30-11f63657ba62'

  def perform
    super(RESOURCE, HEADERS, FILE_NAME)
  end

  private

  def data_for(month:)
    [
      month.strftime(DATE_FORMAT),
      Dossier.visible_by_user_or_administration
        .where(depose_at: month.all_month).count +
      DeletedDossier
        .where(depose_at: month.all_month).count,
    ]
  end
end
