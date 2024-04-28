# frozen_string_literal: true

namespace :after_party do
  desc 'Deployment task: rename_conservation_extension'
  task rename_conservation_extension: :environment do
    puts "Running deploy task 'rename_conservation_extension'"

    BATCH_SIZE = 20_000

    ignored_columns = Dossier.ignored_columns.dup
    Dossier.ignored_columns -= ["en_construction_conservation_extension"]

    dossiers = Dossier.state_en_construction.where.not(en_construction_conservation_extension: 0.days)
    progress = ProgressReport.new((dossiers.count.to_f / BATCH_SIZE).round)
    dossiers.in_batches(of: BATCH_SIZE) do |relation|
      relation.update_all("conservation_extension = en_construction_conservation_extension")
      progress.inc
    end
    progress.finish

    Dossier.ignored_columns = ignored_columns # rubocop:disable Rails/IgnoredColumnsAssignment

    dossiers_without_conservation_extension = Dossier.where(conservation_extension: nil)
    progress = ProgressReport.new((dossiers_without_conservation_extension.count.to_f / BATCH_SIZE).round)
    dossiers_without_conservation_extension.in_batches(of: BATCH_SIZE) do |relation|
      relation.update_all(conservation_extension: 'PT0S')
      progress.inc
    end
    progress.finish

    # Update task as completed.  If you remove the line below, the task will
    # run with every deploy (or every time you call after_party:run).
    AfterParty::TaskRecord
      .create version: AfterParty::TaskRecorder.new(__FILE__).timestamp
  end
end
