class PjsMigrationJob < ApplicationJob
  queue_as :pj_migration_jobs

  def perform(blob_id)
    blob = ActiveStorage::Blob.find(blob_id)

    return if already_moved?(blob)

    service = blob.service
    client = service.client
    container = service.container
    old_key = blob.key
    new_key = "#{blob.created_at.strftime('%Y/%m/%d')}/#{old_key[0..1]}/#{old_key}"

    excon_response = client.copy_object(container,
                               old_key,
                               container,
                               new_key,
                               { "Content-Type" => blob.content_type })

    if excon_response.status == 201
      blob.update_columns(key: new_key)
      client.delete_object(container, old_key)
    end
  end

  def already_moved?(blob)
    blob.key.include?('/')
  end
end
