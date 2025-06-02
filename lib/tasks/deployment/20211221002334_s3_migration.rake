# frozen_string_literal: true

namespace :after_party do
  desc 'Deployment task: s3_migration'
  task s3_migration: :environment do
    puts "Running deploy task 's3_migration'"

    S3Synchronization.reset if ENV.fetch('OUTSCALE_STEP', "") == '0'

    # Update task as completed.  If you remove the line below, the task will
    # run with every deploy (or every time you call after_party:run).
    AfterParty::TaskRecord
      .create version: AfterParty::TaskRecorder.new(__FILE__).timestamp
  end
end
