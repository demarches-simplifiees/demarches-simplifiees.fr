class PjsMigrationJob < ApplicationJob
  queue_as :pj_migration_jobs

  def perform(blob_id)
    blob = Blob.find(blob_id)

    return if already_moved?(blob)

    service = blob.service
    client = service.client
    container = service.container
    old_key = blob.key
    new_key = "#{blob.created_at.year}/#{old_key[0..1]}/#{old_key[2..3]}/#{old_key}"

    excon_response = client.copy_object(container,
                               old_key,
                               container,
                               new_key,
                               { "Content-Type" => blob.content_type })

    if excon_response.status == 201
      blob.update_columns(key: new_key)
      client.delete_object(container, old_key)
    end
  rescue Fog::OpenStack::Storage::NotFound
  end

  def already_moved?(blob)
    blob.key.include?('/')
  end
end
