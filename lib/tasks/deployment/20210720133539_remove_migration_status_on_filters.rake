# frozen_string_literal: true

namespace :after_party do
  desc 'Deployment task: remove_migration_status_on_filters'
  task remove_migration_status_on_filters: :environment do
    rake_puts "Running deploy task 'remove_migration_status_on_filters'"

    # In a9a4f6e2a801b19b127aae8eaec0d1f384b1a53a, a task to migrate ProcedurePresentation's filters
    # was added.
    # This task added a "migrated: true" key to all migrated filters.
    #
    # Now that this task has run, we can safely remove the extra key.

    procedure_presentations = ProcedurePresentation.where("filters -> 'migrated' IS NOT NULL")
    progress = ProgressReport.new(procedure_presentations.count)

    procedure_presentations.find_each do |pp|
      pp.update_column(:filters, pp.filters.except('migrated'))
      progress.inc
    end
    progress.finish

    AfterParty::TaskRecord
      .create version: AfterParty::TaskRecorder.new(__FILE__).timestamp
  end
end
