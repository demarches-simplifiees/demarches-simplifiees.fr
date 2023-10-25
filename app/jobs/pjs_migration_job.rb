class PjsMigrationJob < ApplicationJob
  queue_as :pj_migration_jobs

  def perform(blob_id)
    blob = ActiveStorage::Blob.find(blob_id)

    return if already_moved?(blob)
    return if blob.service_name != "s3"

    service = blob.service
    client = service.client.client
    container = service.bucket.name
    old_key = blob.key
    new_key = "#{blob.created_at.strftime('%Y/%m/%d')}/#{old_key[0..1]}/#{old_key}"

    if service.bucket.object(old_key).exists?
      client.copy_object({ bucket: container, copy_source: "#{container}/#{old_key}", key: new_key })
      if service.bucket.object(new_key).exists?
        blob.update_columns(key: new_key)
        client.delete_object({ bucket: container, key: old_key })
      end
    end
  rescue Aws::S3::Errors::ServiceError
  end

  def already_moved?(blob)
    blob.key.include?('/')
  end
end
