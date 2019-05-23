class DeclarativeProceduresJob < ApplicationJob
  queue_as :cron

  def perform(*args)
    Procedure.declarative.find_each(&:process_dossiers!)
  end
end
