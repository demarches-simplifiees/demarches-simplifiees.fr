# frozen_string_literal: true

namespace :after_party do
  desc 'Deployment task: backfill_dossiers_repetitions'
  task backfill_dossiers_repetitions: :environment do
    puts "Running deploy task 'backfill_dossiers_repetitions'"

    revision_ids = ProcedureRevision.joins(:types_de_champ).where(types_de_champ: { type_champ: :repetition }).distinct.pluck(:id)
    dossier_ids = Dossier.where(revision_id: revision_ids).pluck(:id)

    progress = ProgressReport.new(dossier_ids.size)
    batch_size = 7000
    dossier_ids_to_fix = []
    dossier_ids.in_groups_of(batch_size, false) do |dossier_ids|
      # map dossier ids to revision ids
      revision_id_by_dossier_id = Dossier.where(id: dossier_ids)
        .pluck(:id, :revision_id)
        .index_by(&:first)
        .transform_values(&:last)

      # map revision ids to type de champ repetition ids
      type_de_champ_ids_by_revision_id = ProcedureRevisionTypeDeChamp.joins(:type_de_champ)
        .where(types_de_champ: { type_champ: :repetition }, revision_id: revision_id_by_dossier_id.values.uniq)
        .pluck(:revision_id, :type_de_champ_id)
        .uniq
        .group_by(&:first)
        .transform_values { _1.map(&:last) }

      # find all dossier ids where all repetition type de champ have a champ
      dossier_ids_with_all_repetition_champs = Champ.where(dossier_id: dossier_ids, type: 'Champs::RepetitionChamp')
        .pluck(:dossier_id, :type_de_champ_id)
        .group_by(&:first)
        .transform_values { _1.map(&:last) }
        .filter_map do |dossier_id, type_de_champ_ids|
          revision_id = revision_id_by_dossier_id[dossier_id]
          if type_de_champ_ids.size >= type_de_champ_ids_by_revision_id[revision_id].size
            dossier_id
          end
        end

      dossier_ids_to_fix += dossier_ids - dossier_ids_with_all_repetition_champs
      progress.inc(batch_size)
    end
    progress.finish

    pp "fixing #{dossier_ids_to_fix.size} dossiers"

    dossier_ids_to_fix.in_groups_of(300, false) do |dossier_ids|
      Migrations::BackfillDossierRepetitionJob.perform_later(dossier_ids)
    end

    # Update task as completed.  If you remove the line below, the task will
    # run with every deploy (or every time you call after_party:run).
    AfterParty::TaskRecord
      .create version: AfterParty::TaskRecorder.new(__FILE__).timestamp
  end
end
