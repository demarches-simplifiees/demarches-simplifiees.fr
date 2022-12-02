namespace :after_party do
  desc 'Deployment task: backfill_dossiers_with_routing_data'
  task backfill_dossiers_with_routing_data: :environment do
    puts "Running deploy task 'backfill_dossiers_with_routing_data'"

    progress = ProgressReport.new(Dossier.where(migrated_champ_routage: nil).count)
    ProcedureRevision.where(migrated_champ_routage: nil).find_each do |revision|
      revision_type_de_champ_id = ProcedureRevisionTypeDeChamp
        .joins(:type_de_champ)
        .where(revision:, types_de_champ: { type_champ: 'routage' })
        .limit(1)
        .pick(:type_de_champ_id)

      next if revision_type_de_champ_id.nil?

      revision.dossiers.where(migrated_champ_routage: nil).select(:id, :groupe_instructeur_id, :created_at).in_batches do |dossiers|
        revision.transaction do
          dossiers_in_batch = dossiers.to_a
          Champ.insert_all(dossiers_in_batch.map do |dossier|
            {
              type: 'Champs::RoutageChamp',
              value: dossier.groupe_instructeur_id,
              type_de_champ_id: revision_type_de_champ_id,
              dossier_id: dossier.id,
              private: false,
              created_at: dossier.created_at,
              updated_at: dossier.created_at
            }
          end)
          dossiers.update_all(migrated_champ_routage: true)
          progress.inc(dossiers_in_batch.size)
        end
      end

      revision.update_column(:migrated_champ_routage, true)
    end
    progress.finish

    # Update task as completed.  If you remove the line below, the task will
    # run with every deploy (or every time you call after_party:run).
    AfterParty::TaskRecord
      .create version: AfterParty::TaskRecorder.new(__FILE__).timestamp
  end
end
