# frozen_string_literal: true

namespace :after_party do
  desc 'Deployment task: clean_invalid_procedures'
  task clean_invalid_procedures: :environment do
    puts "Running deploy task 'clean_invalid_procedures'"

    Procedure.with_discarded.where(duree_conservation_etendue_par_ds: nil)
      .update_all(duree_conservation_etendue_par_ds: false)

    Procedure.with_discarded.where(max_duree_conservation_dossiers_dans_ds: nil)
      .update_all(max_duree_conservation_dossiers_dans_ds: Procedure::NEW_MAX_DUREE_CONSERVATION)

    # Update task as completed.  If you remove the line below, the task will
    # run with every deploy (or every time you call after_party:run).
    AfterParty::TaskRecord
      .create version: AfterParty::TaskRecorder.new(__FILE__).timestamp
  end
end
