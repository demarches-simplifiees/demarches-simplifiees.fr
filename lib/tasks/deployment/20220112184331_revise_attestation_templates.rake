# frozen_string_literal: true

namespace :after_party do
  desc 'Deployment task: moving Attestations from Procedure to ProcedureRevision'
  task revise_attestation_templates: :environment do
    rake_puts "Running deploy task 'revise_attestation_templates'"

    revisions = ProcedureRevision
      .joins(procedure: :legacy_attestation_template)
      .where(attestation_template_id: nil)

    progress = ProgressReport.new(revisions.count)

    revisions.find_each do |revision|
      attestation_template_id = revision.procedure.legacy_attestation_template.id
      revision.update_column(:attestation_template_id, attestation_template_id)

      progress.inc
    end
    progress.finish

    # Update task as completed.  If you remove the line below, the task will
    # run with every deploy (or every time you call after_party:run).
    AfterParty::TaskRecord
      .create version: AfterParty::TaskRecorder.new(__FILE__).timestamp
  end
end
