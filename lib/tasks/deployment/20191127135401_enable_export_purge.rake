namespace :after_party do
  desc 'Deployment task: enable_export_purge'
  task enable_export_purge: :environment do
    PurgeStaleExportsJob.set(cron: "*/5 * * * *").perform_later

    AfterParty::TaskRecord.create version: '20191127135401'
  end
end
