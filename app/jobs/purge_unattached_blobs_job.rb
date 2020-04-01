class PurgeUnattachedBlobsJob < CronJob
  self.schedule_expression = "every day at midnight"

  def perform(*args)
    ActiveStorage::Blob.unattached
      .where('active_storage_blobs.created_at < ?', 24.hours.ago)
      .find_each(&:purge_later)
  end
end
