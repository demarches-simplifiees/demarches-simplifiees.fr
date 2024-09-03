# frozen_string_literal: true

class Cron::ReleaseCrashedExportJob < Cron::CronJob
  self.schedule_expression = "every 10 minute"
  SECSCAN_LIMIT = 20_000

  def perform(*args)
    return if !performable?
    export_jobs = jobs_for_current_host

    return if export_jobs.empty?

    host_pids = Sys::ProcTable.ps.map(&:pid)
    export_jobs.each do |job|
      _, pid = hostname_and_pid(job.locked_by)

      reset(job:) if host_pids.exclude?(pid.to_i)
    end
  end

  def reset(job:)
    job.locked_by = nil
    job.locked_at = nil
    job.attempts += 1
    job.save!
  end

  def hostname_and_pid(worker_name)
    matches = /host:(?<host>.*) pid:(?<pid>\d+)/.match(worker_name)
    [matches[:host], matches[:pid]]
  end

  def jobs_for_current_host
    Delayed::Job.where("locked_by like ?", "%#{whoami}%")
      .where(queue: ExportJob.queue_name)
  end

  def whoami
    me, _ = hostname_and_pid(Delayed::Worker.new.name)
    me
  end

  def performable?
    Delayed::Job.count < SECSCAN_LIMIT
  end
end
