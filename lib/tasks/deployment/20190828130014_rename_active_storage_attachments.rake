namespace :after_party do
  desc 'Deployment task: rename_active_storage_attachments'
  task rename_active_storage_attachments: :environment do
    puts "Running deploy task 'rename_active_storage_attachments'"

    ActiveStorage::Attachment.where(name: 'logo_active_storage').update_all(name: 'logo')
    ActiveStorage::Attachment.where(name: 'signature_active_storage').update_all(name: 'signature')
    ActiveStorage::Attachment.where(name: 'pdf_active_storage').update_all(name: 'pdf')

    # Update task as completed.  If you remove the line below, the task will
    # run with every deploy (or every time you call after_party:run).
    AfterParty::TaskRecord.create version: '20190828130014'
  end
end
