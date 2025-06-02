# frozen_string_literal: true

namespace :after_party do
  desc 'Deployment task: active_attestation'
  task active_attestation: :environment do
    puts "Running deploy task 'active_attestation'"

    # Put your task implementation HERE.
    AttestationTemplate.where(procedure_id: 1284).update_all(activated: true)

    # Update task as completed.  If you remove the line below, the task will
    # run with every deploy (or every time you call after_party:run).
    AfterParty::TaskRecord
      .create version: AfterParty::TaskRecorder.new(__FILE__).timestamp
  end
end
