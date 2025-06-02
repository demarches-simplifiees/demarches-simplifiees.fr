# frozen_string_literal: true

namespace :after_party do
  desc 'Deployment task: backfill_revisions_published_at'
  task backfill_revisions_published_at: :environment do
    puts "Running deploy task 'backfill_revisions_published_at'"

    ProcedureRevision
      .joins(:procedure)
      .where('procedures.draft_revision_id != procedure_revisions.id')
      .where(published_at: nil)
      .update_all('published_at = created_at')

    # Update task as completed.  If you remove the line below, the task will
    # run with every deploy (or every time you call after_party:run).
    AfterParty::TaskRecord
      .create version: AfterParty::TaskRecorder.new(__FILE__).timestamp
  end
end
