# frozen_string_literal: true

namespace :after_party do
  desc 'Deployment task: backfill_repetition_champ_without_row_id'
  task backfill_repetition_champ_without_row_id: :environment do
    puts "Running deploy task 'backfill_repetition_champ_without_row_id'"
    # You may need to set a higher statement_timeout when invoking this task for this query
    champs = Champ.where(row_id: nil).where.not(parent_id: nil)

    progress = ProgressReport.new(champs.count)

    row_ids = {}

    champs.group_by { [_1.dossier_id, _1.stable_id] }.values.map { _1.sort_by(&:created_at) }.each do |champs_by_stable_id|
      champs_by_stable_id.each_with_index do |champ, row_index|
        key = [champ.dossier_id, champ.parent_id, row_index]

        row_ids[key] ||= ULID.generate
        row_id = row_ids[key]

        champ.update!(row_id:)

        progress.inc
      end
    end

    progress.finish

    # Update task as completed.  If you remove the line below, the task will
    # run with every deploy (or every time you call after_party:run).
    AfterParty::TaskRecord
      .create version: AfterParty::TaskRecorder.new(__FILE__).timestamp
  end
end
