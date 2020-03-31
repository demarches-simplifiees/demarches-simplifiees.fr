namespace :jobs do
  desc 'Schedule all cron jobs'
  task schedule: :environment do
    glob = Rails.root.join('app', 'jobs', '**', '*_job.rb')
    Dir.glob(glob).each { |f| require f }
    CronJob.subclasses.each(&:schedule)
  end
end
