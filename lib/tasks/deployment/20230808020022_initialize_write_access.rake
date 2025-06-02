# frozen_string_literal: true

namespace :after_party do
  desc 'Deployment task: Sets'
  task initialize_write_access: :environment do
    puts "Running deploy task 'initialize_write_access'"

    # rubocop:disable DS/Unscoped
    APIToken.unscoped.in_batches do |relation|
      relation.update_all write_access: true
      sleep(0.01)
    end
    # rubocop:enable DS/Unscoped

    # Update task as completed.  If you remove the line below, the task will
    # run with every deploy (or every time you call after_party:run).
    AfterParty::TaskRecord
      .create version: AfterParty::TaskRecorder.new(__FILE__).timestamp
  end
end
