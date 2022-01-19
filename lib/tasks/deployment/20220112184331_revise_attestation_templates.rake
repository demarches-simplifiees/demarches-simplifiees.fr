namespace :after_party do
  desc 'Deployment task: moving Attestations from Procedure to ProcedureRevision'
  task revise_attestation_templates: :environment do
    rake_puts "Running deploy task 'revise_attestation_templates'"

    attestation_templates = AttestationTemplate.where.not(procedure_id: nil)
    progress = ProgressReport.new(attestation_templates.count)

    attestation_templates.find_each do |attestation_template|
      ProcedureRevision
        .where(procedure_id: attestation_template.procedure_id, attestation_template_id: nil)
        .update_all(attestation_template_id: attestation_template)
      attestation_template.update_column(:procedure_id, nil)
      progress.inc
    end
    progress.finish

    # Update task as completed.  If you remove the line below, the task will
    # run with every deploy (or every time you call after_party:run).
    AfterParty::TaskRecord
      .create version: AfterParty::TaskRecorder.new(__FILE__).timestamp
  end
end
