namespace :after_party do
  desc 'Deployment task: remove_orphan_dossier_operation_logs'
  task remove_orphan_dossier_operation_logs: :environment do
    puts "Running deploy task 'remove_orphan_dossier_operation_logs'"

    job_limit = 200_000

    not_deletion_orphans = DossierOperationLog
      .not_deletion
      .where.missing(:dossier)
      .limit(job_limit)

    batch_size = 1_000

    rake_puts "Suppression des dols avec operation != supprimer"

    progress = ProgressReport.new(not_deletion_orphans.count)

    not_deletion_orphans.in_batches(of: batch_size) do |b|
      b.destroy_all
      progress.inc(batch_size)
    end

    rake_puts "Supression des serialized des dols avec operation == supprimer"

    deletion_orphans = DossierOperationLog
      .supprimer
      .limit(job_limit)

    progress = ProgressReport.new(deletion_orphans.count)

    deletion_orphans.find_each(batch_size:) do |dossier_operation_log|
      dossier_operation_log.serialized.purge_later
      progress.inc
    end

    AfterParty::TaskRecord
      .create version: AfterParty::TaskRecorder.new(__FILE__).timestamp
  end
end
