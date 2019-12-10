namespace :after_party do
  desc 'Deployment task: enable_seek_and_destroy_job'
  task enable_seek_and_destroy_job: :environment do
    SeekAndDestroyExpiredDossiersJob.set(cron: "0 7 * * *").perform_later
    AfterParty::TaskRecord.create version: '20191203142402'
  end
end
