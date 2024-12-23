# frozen_string_literal: true

namespace :jobs do
  desc 'Schedule all schedulable cron jobs'
  task schedule: :environment do
    schedulable_jobs.each(&:schedule)
  end

  desc 'Display schedule for all schedulable cron jobs'
  task display_schedule: :environment do
    schedulable_jobs.each(&:display_schedule)
  end

  def schedulable_jobs
    glob = Rails.root.join('app', 'jobs', '**', '*_job.rb')
    Dir.glob(glob).each { |f| require f }
    Cron::CronJob.descendants.filter(&:schedulable?)
  end
end
