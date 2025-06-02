# frozen_string_literal: true

namespace :after_party do
  desc 'Deployment task: Remove_s3_synchronisation_jobs'
  task remove_s3_synchronization: :environment do
    puts "Running deploy task 'remove_s3_synchronization'"

    Delayed::Job.where.not(cron: nil).where("handler LIKE ?", "%BlobSynchronization%").destroy_all

    AfterParty::TaskRecord
      .create version: AfterParty::TaskRecorder.new(__FILE__).timestamp
  end
end
