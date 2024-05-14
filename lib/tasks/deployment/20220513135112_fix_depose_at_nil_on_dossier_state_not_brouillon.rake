# frozen_string_literal: true

namespace :after_party do
  desc 'Deployment task: fix_depose_at_nil_on_dossier_state_not_brouillon'
  task fix_depose_at_nil_on_dossier_state_not_brouillon: :environment do
    puts "Running deploy task 'fix_depose_at_nil_on_dossier_state_not_brouillon'"

    # Put your task implementation HERE.
    dossiers_with_depose_at_nil = Dossier.state_not_brouillon.where(depose_at: nil)

    rake_puts "Number of dossiers not in brouillon without depose_at : #{dossiers_with_depose_at_nil.count}"

    dossiers_with_depose_at_nil.update_all("depose_at = en_construction_at")
    # Update task as completed.  If you remove the line below, the task will
    # run with every deploy (or every time you call after_party:run).
    AfterParty::TaskRecord
      .create version: AfterParty::TaskRecorder.new(__FILE__).timestamp
  end
end
