class DeclarativeProceduresJob < CronJob
  self.cron_expression = "* * * * *"

  def perform(*args)
    Procedure.declarative.find_each(&:process_dossiers!)
  end
end
