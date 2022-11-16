namespace :after_party do
  desc 'Deployment task: backfill_procedures_and_dossiers_with_routing_data'
  task backfill_procedures_and_dossiers_with_routing_data: :environment do
    puts "Running deploy task 'backfill_procedures_and_dossiers_with_routing_data'"

    # Put your task implementation HERE.
    procedures = Procedure.with_discarded.includes(draft_revision: [:revision_types_de_champ_public, :types_de_champ], published_revision: [:revision_types_de_champ_public, :types_de_champ])
    progress = ProgressReport.new(procedures.count)
    procedures.find_each do |p|
      if !p.draft_revision.types_de_champ.any?(&:routage?)

        routage_type_de_champ = TypeDeChamp.create(
          type_champ: 'routage',
          libelle: p.routing_criteria_name,
          private: false,
          mandatory: true
        )

        Procedure.transaction do
          p.revisions.each do |revision|
            draft_coordinates = revision.revision_types_de_champ_public.to_a
            ProcedureRevisionTypeDeChamp.create(revision: revision, type_de_champ: routage_type_de_champ, position: 0)
            draft_coordinates.each.with_index(1) do |coordinate, position|
              coordinate.update_column(:position, position)
            end
          end
        end

        p.dossiers.select(:id, :groupe_instructeur_id).includes(:champs_public).in_batches do |dossiers|
          dossiers
            .filter { |dossier| !dossier.champs_public.any? { |champ| champ.type == 'Champs::RoutageChamp' } }
            .each do |dossier|
            Champ.create(
              type: 'Champs::RoutageChamp',
              value: dossier.groupe_instructeur_id,
              type_de_champ: routage_type_de_champ,
              dossier_id: dossier.id,
              private: false
            )
          end
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
