# frozen_string_literal: true

namespace :after_party do
  desc 'Deployment task: backfill_procedure_expires_when_termine_enabled_without_dossiers'
  task backfill_procedure_expires_when_termine_enabled_without_dossiers: :environment do
    puts "Running deploy task 'backfill_procedure_expires_when_termine_enabled_without_dossiers'"

    Procedure.where.missing(:dossiers)
      .where(procedure_expires_when_termine_enabled: false)
      .update_all(procedure_expires_when_termine_enabled: true)

    AfterParty::TaskRecord
      .create version: AfterParty::TaskRecorder.new(__FILE__).timestamp
  end
end
