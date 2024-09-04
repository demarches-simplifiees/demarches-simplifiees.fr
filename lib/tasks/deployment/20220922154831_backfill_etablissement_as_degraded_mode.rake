# frozen_string_literal: true

namespace :after_party do
  desc 'Deployment task: backfill_etablissement_as_degraded_mode'
  task backfill_etablissement_as_degraded_mode: :environment do
    puts "Running deploy task 'backfill_etablissement_as_degraded_mode'"

    Etablissement.joins(:dossier).where(adresse: nil).find_each do |etablissement|
      begin
        procedure_id = etablissement.dossier.procedure.id
        APIEntrepriseService.update_etablissement_from_degraded_mode(etablissement, procedure_id)
      rescue => e
        Sentry.capture_exception(e)
      end
      sleep((0.5).second)
    end
    # Put your task implementation HERE.

    # Update task as completed.  If you remove the line below, the task will
    # run with every deploy (or every time you call after_party:run).
    AfterParty::TaskRecord
      .create version: AfterParty::TaskRecorder.new(__FILE__).timestamp
  end
end
