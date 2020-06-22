namespace :jobs do
  desc 'Schedule all cron jobs'
  task schedule: :environment do
    glob = Rails.root.join('app', 'jobs', '**', '*_job.rb')
    Dir.glob(glob).each { |f| require f }
    CronJob.subclasses.each(&:schedule)
  end

  desc 'Display schedule for all cron jobs'
  task display_schedule: :environment do
    glob = Rails.root.join('app', 'jobs', '**', '*_job.rb')
    Dir.glob(glob).each { |f| require f }
    CronJob.subclasses.each(&:display_schedule)
  end
end
