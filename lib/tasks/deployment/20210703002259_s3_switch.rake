namespace :after_party do
  desc 'Deployment task: last'
  task s3_switch: :environment do
    if ENV.fetch('STORAGE_SWITCH', '').present?
      puts "Running deploy task 's3_switch'"
      S3Synchronization.switch_synchronize

      # Update task as completed.  If you remove the line below, the task will
      # run with every deploy (or every time you call after_party:run).
      # AfterParty::TaskRecord
      #   .create version: AfterParty::TaskRecorder.new(__FILE__).timestamp
    end
  end
end
