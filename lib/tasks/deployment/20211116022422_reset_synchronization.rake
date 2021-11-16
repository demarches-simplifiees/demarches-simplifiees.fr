namespace :after_party do
  desc 'Deployment task: reset synchronization'
  task reset_synchronization: :environment do
    puts "Running deploy task 'reset_synchronization'"

    S3Synchronization.reset

    # Update task as completed.  If you remove the line below, the task will
    # run with every deploy (or every time you call after_party:run).
    AfterParty::TaskRecord
      .create version: AfterParty::TaskRecorder.new(__FILE__).timestamp
  end
end
