class DeclarativeProceduresJob < CronJob
  self.schedule_expression = "every 1 minute"

  def perform(*args)
    Procedure.declarative.find_each(&:process_dossiers!)
  end
end
