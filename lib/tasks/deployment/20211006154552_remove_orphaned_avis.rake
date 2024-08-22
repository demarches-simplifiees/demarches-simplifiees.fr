# frozen_string_literal: true

namespace :after_party do
  desc 'Deployment task: remove_orphaned_avis'
  task remove_orphaned_avis: :environment do
    puts "Running deploy task 'remove_orphaned_avis'"

    avis = Avis.unscope(:joins)
      .joins('LEFT JOIN dossiers ON dossiers.id = avis.dossier_id')
      .where(dossiers: { id: nil })
    progress = ProgressReport.new(avis.count)

    avis.find_each do |avis|
      avis.destroy
      progress.inc
    end
    progress.finish

    # Update task as completed.  If you remove the line below, the task will
    # run with every deploy (or every time you call after_party:run).
    AfterParty::TaskRecord
      .create version: AfterParty::TaskRecorder.new(__FILE__).timestamp
  end
end
