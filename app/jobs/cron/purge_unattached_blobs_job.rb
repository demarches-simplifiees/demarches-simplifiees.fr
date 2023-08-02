class Cron::PurgeUnattachedBlobsJob < Cron::CronJob
  self.schedule_expression = "every day at midnight"

  def perform
    # .in_batches { _1.each... } is more efficient in this case that in_batches.each_record or find_each
    # because it plucks only ids in a preliminary query, then load records with selected columns in batches by ids.
    # This is faster than other batch strategies, which load at once selected columns with an ORDER BY in the same query, triggering timeouts.
    ActiveStorage::Blob.unattached.select(:id, :service_name, :created_at).in_batches do |relation|
      relation.each do |blob|
        return if blob.created_at > 24.hours.ago # not in where() because it's not an indexed column

        blob.purge_later
      end
    end
  end
end
