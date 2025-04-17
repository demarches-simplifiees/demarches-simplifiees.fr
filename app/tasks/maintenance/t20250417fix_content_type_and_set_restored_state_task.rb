# frozen_string_literal: true

module Maintenance
  class T20250417fixContentTypeAndSetRestoredStateTask < MaintenanceTasks::Task
    # Ce script est utilisé pour corriger le content-type des fichiers qui ont été
    # restaurés depuis le backup.
    # Elle change é́galement le status TaskLog concerné à state 'restored'.

    csv_collection(headers: ['blob_key'])

    include RunnableOnDeployConcern
    include StatementsHelpersConcern

    # Uncomment only if this task MUST run imperatively on its first deployment.
    # If possible, leave commented for manual execution later.
    # run_on_first_deploy

    def process(row)
      blob_key = row['blob_key']

      blob = ActiveStorage::Blob.find_by(key: blob_key)

      if blob.nil?
        TaskLog.where("data->>'blob_key' = ?", blob_key)
          .update_all(%(data = jsonb_set(data, '{state}', '"not present in db"')))
        return
      end

      container = blob.service.container

      found = true
      begin
        # we fix the content type
        client.post_object(container, blob_key, { 'Content-Type' => blob.content_type })
      rescue Fog::OpenStack::Storage::NotFound
        found = false
      end

      if found
        TaskLog.where("data->>'blob_key' = ?", blob_key)
          .update_all(%(data = jsonb_set(data, '{state}', '"restored"')))
      else
        TaskLog.where("data->>'blob_key' = ?", blob_key)
          .update_all(%(data = jsonb_set(data, '{state}', '"restoration failed"')))
      end
    end

    def client
      ActiveStorage::Blob.service.send(:client)
    end
  end
end
