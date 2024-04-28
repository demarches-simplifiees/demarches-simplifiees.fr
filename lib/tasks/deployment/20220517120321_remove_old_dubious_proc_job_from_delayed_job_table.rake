# frozen_string_literal: true

namespace :after_party do
  desc 'Deployment task: remove_old_find_dubious_procedures_job_from_delayed_job_table'
  task remove_old_dubious_proc_job_from_delayed_job_table: :environment do
    puts "Running deploy task 'remove_old_dubious_proc_job_from_delayed_job_table'"

    cron = Delayed::Job.where.not(cron: nil)
      .where("handler LIKE ?", "%FindDubiousProceduresJob%")
      .first
    cron.destroy if cron

    AfterParty::TaskRecord
      .create version: AfterParty::TaskRecorder.new(__FILE__).timestamp
  end
end
