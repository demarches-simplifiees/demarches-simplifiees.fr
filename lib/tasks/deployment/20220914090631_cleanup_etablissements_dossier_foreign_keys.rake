# frozen_string_literal: true

namespace :after_party do
  desc 'Deployment task: cleanup_etablissements_dossier_foreign_keys'
  task cleanup_etablissements_dossier_foreign_keys: :environment do
    puts "Running deploy task 'cleanup_etablissements_dossier_foreign_keys'"

    etablissements_with_invalid_dossier = Etablissement.where.not(dossier_id: nil).where.missing(:dossier)
    etablissements_with_invalid_dossier_count = etablissements_with_invalid_dossier.count

    if etablissements_with_invalid_dossier_count > 0
      progress = ProgressReport.new(etablissements_with_invalid_dossier_count)
      Etablissement.where.not(dossier_id: nil).in_batches(of: 10_000) do |etablissements|
        count = etablissements.where.missing(:dossier).count
        if count > 0
          etablissements.where.missing(:dossier).update_all(dossier_id: nil)
          progress.inc(count)
        end
      end
      progress.finish
    else
      puts "No etablissements with invalid dossier found"
    end

    # Update task as completed.  If you remove the line below, the task will
    # run with every deploy (or every time you call after_party:run).
    AfterParty::TaskRecord
      .create version: AfterParty::TaskRecorder.new(__FILE__).timestamp
  end
end
