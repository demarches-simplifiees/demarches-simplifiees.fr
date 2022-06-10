class Cron::DeclarativeProceduresJob < Cron::CronJob
  self.schedule_expression = "every 1 minute"

  def perform(*args)
    Procedure.declarative.find_each do |procedure|
      begin
        procedure.process_dossiers!
      rescue => e
        Sentry.capture_exception(e)
      end
    end
  end
end
