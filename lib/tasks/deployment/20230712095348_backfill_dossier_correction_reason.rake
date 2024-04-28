# frozen_string_literal: true

namespace :after_party do
  desc 'Deployment task: backfill_default_dossier_correction_reason'
  task backfill_dossier_correction_reason: :environment do
    puts "Running deploy task 'backfill_default_dossier_correction_reason'"

    DossierCorrection.where(kind: 'correction').update_all(reason: 'incorrect')
    DossierCorrection.where(kind: 'incomplete').update_all(reason: 'incomplete')

    # Update task as completed.  If you remove the line below, the task will
    # run with every deploy (or every time you call after_party:run).
    AfterParty::TaskRecord
      .create version: AfterParty::TaskRecorder.new(__FILE__).timestamp
  end
end
