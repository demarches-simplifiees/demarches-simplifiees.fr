class Cron::StalledDeclarativeProceduresJob < Cron::CronJob
  self.schedule_expression = "every 10 minute"

  def perform(*args)
    Procedure.declarative.find_each do |procedure|
      begin
        procedure.process_stalled_dossiers!
      rescue => e
        Sentry.set_tags(procedure: procedure.id)
        Sentry.capture_exception(e)
      end
    end
  end
end
