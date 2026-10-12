# frozen_string_literal: true

module Maintenance
  class T20261012purgeOutOfScopeAPIEntrepriseJobsTask < MaintenanceTasks::Task
    # Removes the API Entreprise jobs that APIEntrepriseService would no longer enqueue, because their
    # etablissement is out of the API's scope, from the scheduled, retrying and dead jobs. A job whose
    # etablissement is gone goes too: it would be discarded.
    #
    # Queues are left alone: their jobs run within minutes and, if they fail, land in the retries,
    # while removing one from a list (LREM) scans it whole and blocks Redis on a long one.

    FETCHABLE = {
      "APIEntreprise::ExercicesJob" => :exercices_fetchable?,
      "APIEntreprise::ExtraitKbisJob" => :extrait_kbis_fetchable?,
      "APIEntreprise::AssociationJob" => :association_fetchable?,
      "APIEntreprise::EffectifsJob" => :effectifs_fetchable?,
      "APIEntreprise::EffectifsAnnuelsJob" => :effectifs_fetchable?,
    }.freeze

    no_collection

    def process
      sources.each do |source|
        jobs = jobs_to_check(source)
        etablissements = Etablissement.where(id: jobs.map { it.display_args.first }).index_by(&:id)

        removed = jobs.count do |job|
          etablissement = etablissements[job.display_args.first]
          next false if etablissement&.public_send(FETCHABLE.fetch(job.display_class))

          remove(source, job)
        end

        Rails.logger.info("#{self.class.name}: removed #{removed} of #{jobs.size} API Entreprise jobs from #{source.name}")
      end
    end

    private

    def sources = [Sidekiq::ScheduledSet.new, Sidekiq::RetrySet.new, Sidekiq::DeadSet.new]

    # Collected before removing anything: JobSet#each pages by an offset only
    # its own #delete keeps up to date, so it skips jobs removed mid-iteration.
    def jobs_to_check(source)
      source.filter { it.display_class.in?(FETCHABLE) }
    end

    # false when the scheduler or a retry took the job in the meantime
    # (SortedEntry#delete can't tell: it returns ZREM's 0 or 1, both truthy)
    def remove(source, job)
      Sidekiq.redis { it.zrem(source.name, job.value) } == 1
    end
  end
end
