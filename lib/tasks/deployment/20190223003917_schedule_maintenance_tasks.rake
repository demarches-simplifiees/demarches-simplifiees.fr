namespace :after_party do
  desc 'Deployment task: enqueue_cron_tasks'
  task schedule_maintenance_tasks: :environment do
    puts "Running deploy task 'schedule_maintenance_tasks'"

    # first remove all cron entries
    Delayed::Job.where("queue = 'cron'").destroy_all
    # next install cron tasks
    AutoArchiveProcedureJob.set(cron: "1 0 * * *").perform_later
    WeeklyOverviewJob.set(cron: "0 7 * * 0").perform_later
    FindDubiousProceduresJob.set(cron: "1 7 * * *").perform_later
    Administrateurs::ActivateBeforeExpirationJob.set(cron: "2 7 * * *").perform_later
    WarnExpiringDossiersJob.set(cron: "3 7 1 * *").perform_later

    # Update task as completed.  If you remove the line below, the task will
    # run with every deploy (or every time you call after_party:run).
    AfterParty::TaskRecord.create version: '20190223003917'
  end # task :schedule_maintenance_tasks
end # namespace :after_party
