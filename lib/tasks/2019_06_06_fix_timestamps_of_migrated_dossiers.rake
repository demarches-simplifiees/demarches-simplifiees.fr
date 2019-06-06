require Rails.root.join("lib", "tasks", "task_helper")

namespace :fix_timestamps_of_migrated_dossiers do
  desc 'Fix the timestamps of dossiers affected by the faulty PJ migration'
  task run: :environment do
    affected_time_range = Time.utc(2019, 6, 4, 8, 0)..Time.utc(2019, 6, 4, 18, 0)
    dossiers = Dossier.unscoped.where(procedure_id: 0..1000).where(updated_at: affected_time_range)

    progress = ProgressReport.new(dossiers.count)

    dossiers.find_each do |dossier|
      fixed_updated_at = dossier.processed_at || dossier.en_instruction_at || dossier.en_construction_at || dossier.champs.last.updated_at || nil
      dossier.update_column(:updated_at, fixed_updated_at)

      progress.inc
    end
    progress.finish
  end
end
