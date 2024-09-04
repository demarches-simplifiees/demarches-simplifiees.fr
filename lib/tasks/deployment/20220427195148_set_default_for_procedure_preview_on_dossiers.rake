# frozen_string_literal: true

namespace :after_party do
  desc 'Deployment task: set_default_for_procedure_preview_on_dossiers'
  task set_default_for_procedure_preview_on_dossiers: :environment do
    puts "Running deploy task 'set_default_for_procedure_preview_on_dossiers'"

    Dossier
      .where(for_procedure_preview: nil)
      .in_batches(of: 5_000)
      .update_all(for_procedure_preview: false)

    # Update task as completed.  If you remove the line below, the task will
    # run with every deploy (or every time you call after_party:run).
    AfterParty::TaskRecord
      .create version: AfterParty::TaskRecorder.new(__FILE__).timestamp
  end
end
