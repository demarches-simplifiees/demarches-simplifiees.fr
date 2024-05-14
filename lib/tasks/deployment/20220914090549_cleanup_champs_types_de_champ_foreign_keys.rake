# frozen_string_literal: true

namespace :after_party do
  desc 'Deployment task: cleanup_champs_types_de_champ_foreign_keys'
  task cleanup_champs_types_de_champ_foreign_keys: :environment do
    puts "Running deploy task 'cleanup_champs_types_de_champ_foreign_keys'"

    champs_with_invalid_type_de_champ = Champ.where.not(type_de_champ_id: nil).where.missing(:type_de_champ)
    champs_with_invalid_type_de_champ_count = champs_with_invalid_type_de_champ.count

    if champs_with_invalid_type_de_champ_count > 0
      progress = ProgressReport.new(champs_with_invalid_type_de_champ_count)
      Champ.where.not(type_de_champ_id: nil).in_batches(of: 600_000) do |champs|
        scope = champs.where.missing(:type_de_champ)
        count = scope.count
        if count > 0
          Champ.where(parent_id: scope).destroy_all
          scope.destroy_all
          progress.inc(count)
        end
      end
      progress.finish
    else
      puts "No champs with invalid type_de_champ found"
    end

    # Update task as completed.  If you remove the line below, the task will
    # run with every deploy (or every time you call after_party:run).
    AfterParty::TaskRecord
      .create version: AfterParty::TaskRecorder.new(__FILE__).timestamp
  end
end
