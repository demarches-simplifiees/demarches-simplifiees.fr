namespace :after_party do
  desc 'Deployment task: backfill_procedures_with_routing_data'
  task backfill_procedures_with_routing_data: :environment do
    puts "Running deploy task 'backfill_procedures_with_routing_data'"

    procedures = Procedure
      .with_discarded
      .includes(revisions: [:revision_types_de_champ_public])
      .where(migrated_champ_routage: nil)

    progress = ProgressReport.new(procedures.count)
    procedures.find_each do |procedure|
      if ProcedureRevisionTypeDeChamp.joins(:type_de_champ).exists?(revision_id: procedure.draft_revision_id, types_de_champ: { type_champ: 'routage' })
        procedure.update_column(:migrated_champ_routage, true)
      else
        procedure.transaction do
          routage_type_de_champ = TypeDeChamp.create!(
            type_champ: 'routage',
            libelle: procedure.routing_criteria_name || 'Votre ville',
            private: false,
            mandatory: true
          )

          procedure.revisions.each do |revision|
            draft_coordinates = revision.revision_types_de_champ_public.to_a
            ProcedureRevisionTypeDeChamp.create(revision: revision, type_de_champ: routage_type_de_champ, position: 0)
            draft_coordinates.each.with_index(1) do |coordinate, position|
              coordinate.update_column(:position, position)
            end
          end

          procedure.update_column(:migrated_champ_routage, true)
        end
      end

      progress.inc
    end
    progress.finish

    # Update task as completed.  If you remove the line below, the task will
    # run with every deploy (or every time you call after_party:run).
    AfterParty::TaskRecord
      .create version: AfterParty::TaskRecorder.new(__FILE__).timestamp
  end
end
