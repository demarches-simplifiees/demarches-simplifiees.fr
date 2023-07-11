namespace :after_party do
  desc 'Deployment task: backfill_dossiers_repetitions'
  task backfill_dossiers_repetitions: :environment do
    puts "Running deploy task 'backfill_dossiers_repetitions'"

    revision_ids = ProcedureRevision.joins(:types_de_champ).where(types_de_champ: { type_champ: :repetition }).distinct.pluck(:id)
    dossier_ids = Dossier.where(revision_id: revision_ids).pluck(:id)

    progress = ProgressReport.new(dossier_ids.size)
    dossier_ids_to_fix = []
    dossier_ids.in_groups_of(10000, false) do |dossier_ids|
      dossier_ids_with_repetition = Champ.where(dossier_id: dossier_ids, type: 'Champs::RepetitionChamp').pluck(:dossier_id).uniq
      dossier_ids_to_fix += dossier_ids - dossier_ids_with_repetition
      progress.inc(10000)
    end
    progress.finish

    pp "fixing #{dossier_ids_to_fix.size} dossiers"

    dossier_ids_to_fix.in_groups_of(100, false) do |dossier_ids|
      Migrations::BackfillDossierRepetitionJob.perform_later(dossier_ids)
    end

    # Update task as completed.  If you remove the line below, the task will
    # run with every deploy (or every time you call after_party:run).
    AfterParty::TaskRecord
      .create version: AfterParty::TaskRecorder.new(__FILE__).timestamp
  end
end
