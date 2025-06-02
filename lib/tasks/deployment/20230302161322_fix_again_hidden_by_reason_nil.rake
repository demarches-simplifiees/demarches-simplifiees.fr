# frozen_string_literal: true

namespace :after_party do
  desc 'Deployment task: fix_again_hidden_by_reason_nil'
  task fix_again_hidden_by_reason_nil: :environment do
    puts "Running deploy task 'fix_again_hidden_by_reason_nil'"

    Dossier.en_construction_expired_to_delete.where(hidden_by_reason: nil).update_all(hidden_by_reason: :user_request)
    Dossier.termine_expired_to_delete.where(hidden_by_reason: nil).update_all(hidden_by_reason: :user_request)

    # Update task as completed.  If you remove the line below, the task will
    # run with every deploy (or every time you call after_party:run).
    AfterParty::TaskRecord
      .create version: AfterParty::TaskRecorder.new(__FILE__).timestamp
  end
end
