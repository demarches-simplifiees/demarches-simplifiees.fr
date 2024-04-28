# frozen_string_literal: true

namespace :after_party do
  desc 'Deployment task: truncate_exports'
  task truncate_exports: :environment do
    puts "Running deploy task 'truncate_exports'"

    Export.in_batches.destroy_all

    # Update task as completed.  If you remove the line below, the task will
    # run with every deploy (or every time you call after_party:run).
    AfterParty::TaskRecord
      .create version: AfterParty::TaskRecorder.new(__FILE__).timestamp
  end
end
