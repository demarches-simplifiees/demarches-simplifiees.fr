# frozen_string_literal: true

namespace :after_party do
  desc 'Deployment task: cleanup_champs_etablissement_foreign_keys'
  task cleanup_champs_etablissement_foreign_keys: :environment do
    puts "Running deploy task 'cleanup_champs_etablissement_foreign_keys'"

    champs_with_invalid_etablissement = Champ.where.not(etablissement_id: nil).where.missing(:etablissement)
    champs_with_invalid_etablissement_count = champs_with_invalid_etablissement.count

    if champs_with_invalid_etablissement_count > 0
      progress = ProgressReport.new(champs_with_invalid_etablissement_count)
      Champ.where.not(etablissement_id: nil).in_batches(of: 10_000) do |champs|
        count = champs.where.missing(:etablissement).count
        if count > 0
          champs.where.missing(:etablissement).update_all(etablissement_id: nil)
          progress.inc(count)
        end
      end
      progress.finish
    else
      puts "No champs with invalid etablissement found"
    end

    # Update task as completed.  If you remove the line below, the task will
    # run with every deploy (or every time you call after_party:run).
    AfterParty::TaskRecord
      .create version: AfterParty::TaskRecorder.new(__FILE__).timestamp
  end
end
