# frozen_string_literal: true

namespace :after_party do
  desc 'Deployment task: backfill_row_id_on_champs'
  task backfill_row_id_on_champs: :environment do
    puts "Running deploy task 'backfill_row_id_on_champs'"

    champs_to_fill = Champ.where(row_id: nil).where.not(parent_id: nil)
    progress = ProgressReport.new(champs_to_fill.count)

    champs = champs_to_fill.pluck(:parent_id, :row, :id)
    pp "found #{champs.size} champs to fill"

    row_ids = Champ.where.not(row_id: nil)
      .distinct(:row_id)
      .pluck(:parent_id, :row, :row_id)
      .map { [[_1.first, _1.second], _1.last] }.to_h
    pp "found #{row_ids.size} existing row ids"

    champs_by_row = champs.group_by { [_1.first, _1.second] }.transform_values { _1.map(&:last) }
    pp "found #{champs_by_row.size} rows to fill"

    champs_by_row.to_a.sort_by(&:first).in_groups_of(5_000) do |batch|
      batch = batch.lazy.compact.flat_map do |(key, champs)|
        row_ids[key] ||= ULID.generate
        champs&.map { [row_ids[key], _1] } || []
      end.group_by(&:first).transform_values { _1.map(&:last) }

      Migrations::BackfillRowIdJob.perform_later(batch)

      progress.inc(batch.size)
    end

    progress.finish

    # Update task as completed.  If you remove the line below, the task will
    # run with every deploy (or every time you call after_party:run).
    AfterParty::TaskRecord
      .create version: AfterParty::TaskRecorder.new(__FILE__).timestamp
  end
end
