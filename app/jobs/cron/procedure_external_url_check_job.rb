class Cron::ProcedureExternalURLCheckJob < Cron::CronJob
  self.schedule_expression = "every week on monday at 1 am"

  def perform
    Procedure.with_external_urls.find_each { ::ProcedureExternalURLCheckJob.perform_later(_1) }
  end
end
