# frozen_string_literal: true

namespace :after_party do
  desc 'Deployment task: setup_first_stats'
  task setup_first_stats: :environment do
    Stat.update_stats

    # Update task as completed.  If you remove the line below, the task will
    # run with every deploy (or every time you call after_party:run).
    AfterParty::TaskRecord
      .create version: AfterParty::TaskRecorder.new(__FILE__).timestamp
  end
end
