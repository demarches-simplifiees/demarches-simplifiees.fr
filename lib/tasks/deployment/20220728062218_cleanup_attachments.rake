# frozen_string_literal: true

namespace :after_party do
  desc 'Deployment task: cleanup_attachments'
  task cleanup_attachments: :environment do
    puts "Running deploy task 'cleanup_attachments'"

    invalid_attachments = ActiveStorage::Attachment.where.missing(:blob)
    invalid_attachments_count = invalid_attachments.size

    if invalid_attachments.any?
      invalid_attachments.destroy_all
      puts "#{invalid_attachments_count} with blob that doesn't exist have been destroyed"
    else
      puts "No attachments with blob that doesn't exist found"
    end

    # Update task as completed.  If you remove the line below, the task will
    # run with every deploy (or every time you call after_party:run).
    AfterParty::TaskRecord
      .create version: AfterParty::TaskRecorder.new(__FILE__).timestamp
  end
end
