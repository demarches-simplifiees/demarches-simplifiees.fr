# frozen_string_literal: true

namespace :after_party do
  desc 'Deployment task: rename_email_event_dolist_method'
  task rename_email_event_dolist_method: :environment do
    puts "Running deploy task 'rename_email_event_dolist_method'"

    # Put your task implementation HERE.
    email_events = EmailEvent.where(method: 'dolist')
    progress = ProgressReport.new(email_events.count)
    email_events.in_batches do |relation|
      count = relation.count
      relation.update_all(method: 'dolist_smtp')
      progress.inc(count)
    end
    progress.finish
    # Update task as completed.  If you remove the line below, the task will
    # run with every deploy (or every time you call after_party:run).
    AfterParty::TaskRecord
      .create version: AfterParty::TaskRecorder.new(__FILE__).timestamp
  end
end
