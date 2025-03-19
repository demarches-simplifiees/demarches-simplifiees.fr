# frozen_string_literal: true

namespace :after_party do
  desc 'Deployment task: attestation_template_v2_as_draft'
  task backfill_attestation_template_v2_as_draft: :environment do
    puts "Running deploy task 'backfill_attestation_template_v2_as_draft'"

    AttestationTemplate.v2.update_all(state: :draft)

    # Update task as completed.  If you remove the line below, the task will
    # run with every deploy (or every time you call after_party:run).
    AfterParty::TaskRecord
      .create version: AfterParty::TaskRecorder.new(__FILE__).timestamp
  end
end
