# frozen_string_literal: true

class Cron::PurgeUnattachedBlobsJob < Cron::CronJob
  self.schedule_expression = "every day at 00:30"

  def perform
    # .in_batches { _1.each... } is more efficient in this case that in_batches.each_record or find_each
    # because it plucks only ids in a preliminary query, then load records with selected columns in batches by ids.
    # This is faster than other batch strategies, which load at once selected columns with an ORDER BY in the same query, triggering timeouts.
    #
    # .where(created_at: 1.week.ago..1.day.ago) to limit the number of records to be joined
    # to the attachments table because of the unattached scope. Otherwise, it is triggering timeouts.
    #
    # the creation of an index on created_at does not seem required yet.
    #
    # caveats: the job needs to be run at least once a week to avoid missing blobs
    ActiveStorage::Blob
      .where(created_at: 1.week.ago..1.day.ago)
      .unattached
      .select(:id, :service_name)
      .in_batches do |relation|
      relation.each(&:purge_later)
    end
  end
end
