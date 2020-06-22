class DiscardedProceduresDeletionJob < CronJob
  self.schedule_expression = "every day at 1 am"

  def perform(*args)
    Procedure.discarded_expired.find_each do |procedure|
      procedure.dossiers.with_discarded.destroy_all
      procedure.destroy
    end
  end
end
