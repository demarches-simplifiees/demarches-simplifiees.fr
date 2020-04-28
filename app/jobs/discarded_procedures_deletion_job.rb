class DiscardedProceduresDeletionJob < CronJob
  self.cron_expression = "0 7 * * *"

  def perform(*args)
    Procedure.discarded_expired.find_each do |procedure|
      procedure.dossiers.with_discarded.destroy_all
      procedure.destroy
    end
  end
end
