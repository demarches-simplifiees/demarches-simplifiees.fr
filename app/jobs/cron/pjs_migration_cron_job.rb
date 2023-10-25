class Cron::PjsMigrationCronJob < Cron::CronJob
  self.schedule_expression = "every 15 minutes"

  def perform(*args)
    # avoid reschedule enqueued jobs
    # but ignore fail jobs
    return if migration_jobs.count > 100

    blobs = ActiveStorage::Blob
      .where.not("key LIKE '%/%'")
      .where(service_name: "s3")
      .limit(200_000)

    blobs.in_batches { |batch| batch.ids.each { |id| PjsMigrationJob.perform_later(id) } }
  end

  def self.schedulable?
    ENV.fetch("MIGRATE_PJS", "enabled") == "enabled"
  end

  private

  def migration_jobs
    Delayed::Job
      .where(queue: 'pj_migration_jobs')
  end
end
