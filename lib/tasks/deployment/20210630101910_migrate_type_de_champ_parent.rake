# frozen_string_literal: true

namespace :after_party do
  desc 'Deployment task: migrate_type_de_champ_parent'
  task migrate_type_de_champ_parent: :environment do
    puts "Running deploy task 'migrate_type_de_champ_parent'"

    types_de_champ = TypeDeChamp
      .where.not(parent_id: nil)
      .where(migrated_parent: nil)
      .includes(:revisions, parent: :revision_type_de_champ)

    progress = ProgressReport.new(types_de_champ.count)
    types_de_champ.find_each do |type_de_champ|
      type_de_champ.migrate_parent!
      progress.inc
    end
    progress.finish

    # Update task as completed.  If you remove the line below, the task will
    # run with every deploy (or every time you call after_party:run).
    AfterParty::TaskRecord
      .create version: AfterParty::TaskRecorder.new(__FILE__).timestamp
  end
end
