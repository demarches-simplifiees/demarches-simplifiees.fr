# frozen_string_literal: true

namespace :after_party do
  desc 'Deployment task: delete_entries_without_user to prepare future db constraints'
  task clean_france_connect: :environment do
    puts "Running deploy task 'clean_france_connect'"

    FranceConnectInformation
      .where.missing(:user)
      .destroy_all

    # Update task as completed.  If you remove the line below, the task will
    # run with every deploy (or every time you call after_party:run).
    AfterParty::TaskRecord
      .create version: AfterParty::TaskRecorder.new(__FILE__).timestamp
  end
end
