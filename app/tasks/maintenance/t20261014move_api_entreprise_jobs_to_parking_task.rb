# frozen_string_literal: true

module Maintenance
  class T20261014moveAPIEntrepriseJobsToParkingTask < MaintenanceTasks::Task
    # Moves the waiting Sidekiq jobs of an API Entreprise class whose provider is down
    # to parked_api_entreprise_fetches, which Cron::RetryParkedAPIEntrepriseFetchesJob
    # replays once the provider is back.
    #
    # sources: `garage` queue (T20260928parkSidekiqJobsTask), the class's queue, `low`
    #          (where the cron replays), retrying and scheduled jobs
    # line:    keeps the job's creation date, so the cron gives up a month after the first
    #          enqueue, not a month after the move
    #
    # The line is written before the job leaves Redis: an interrupted run loses nothing
    # and can be run again. Don't release the garage meanwhile, it is drained from its tail.

    GARAGE = T20260928parkSidekiqJobsTask::GARAGE
    BATCH_SIZE = 1_000
    JOB_CLASSES = APIEntreprise::Job::PING_KEY_BY_JOB.keys.map { "APIEntreprise::#{it}" }.freeze

    attribute :job_class, :string, default: "APIEntreprise::BilansBdfJob"
    validates :job_class, inclusion: { in: JOB_CLASSES }

    def collection
      queues = [GARAGE, job_class.constantize.queue_name, "low"].uniq.map { Sidekiq::Queue.new(it) }
      [*queues, Sidekiq::RetrySet.new, Sidekiq::ScheduledSet.new]
    end

    def process(source)
      moved = source.name == GARAGE ? drain_garage : move(source)
      Rails.logger.info("#{self.class.name}: moved #{moved} #{job_class} from #{source.name} to the parking")
    end

    private

    # LREM scans the whole list for each job, too slow on 150 000 of them: take the
    # batches off the tail instead, and push the other classes' jobs back at the head.
    def drain_garage
      key = "queue:#{GARAGE}"
      left = Sidekiq.redis { it.llen(key) }
      moved = 0

      while left > 0
        size = [BATCH_SIZE, left].min
        jobs = Sidekiq.redis { it.lrange(key, -size, -1) }.map { Sidekiq::JobRecord.new(it) }
        to_move, others = jobs.partition { it.display_class == job_class }

        park(to_move)
        Sidekiq.redis do |conn|
          conn.multi do |transaction|
            transaction.ltrim(key, 0, -size - 1)
            transaction.lpush(key, others.map(&:value).reverse) if others.any?
          end
        end

        moved += to_move.size
        left -= size
      end

      moved
    end

    # Collected before removing anything: JobSet#each pages by an offset only
    # its own #delete keeps up to date, so it skips jobs removed mid-iteration.
    def move(source)
      source.filter { it.display_class == job_class }.each_slice(BATCH_SIZE).sum do |jobs|
        park(jobs)
        jobs.count { remove(source, it) }
      end
    end

    # A job whose etablissement is gone would be discarded: it gets no line.
    def park(jobs)
      etablissement_ids = Etablissement.where(id: jobs.map { it.display_args.first }).ids.to_set
      now = Time.current

      rows = jobs
        .filter { it.display_args.first.in?(etablissement_ids) }
        .sort_by(&:created_at)
        .uniq { it.display_args.first }
        .map do |job|
          etablissement_id, procedure_id = job.display_args
          { etablissement_id:, job: job_class.demodulize, procedure_id:, arguments: job.args[0]["arguments"], code: 503, created_at: job.created_at, updated_at: now }
        end
      return if rows.empty?

      ParkedAPIEntrepriseFetch.upsert_all(rows,
        unique_by: [:etablissement_id, :job],
        on_duplicate: Arel.sql("created_at = LEAST(parked_api_entreprise_fetches.created_at, EXCLUDED.created_at)"))
    end

    # false when a worker or the scheduler took the job in the meantime
    # (SortedEntry#delete can't tell: it returns ZREM's 0 or 1, both truthy)
    def remove(source, job)
      removed = Sidekiq.redis do |conn|
        if source.is_a?(Sidekiq::Queue)
          conn.lrem("queue:#{source.name}", 1, job.value)
        else
          conn.zrem(source.name, job.value)
        end
      end
      removed == 1
    end
  end
end
