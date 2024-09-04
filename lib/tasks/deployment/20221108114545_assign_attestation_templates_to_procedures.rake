# frozen_string_literal: true

namespace :after_party do
  desc 'Deployment task: assign_attestation_templates_to_procedures'
  task assign_attestation_templates_to_procedures: :environment do
    puts "Running deploy task 'assign_attestation_templates_to_procedures'"

    procedures = Procedure.joins(revisions: :attestation_template, draft_revision: :attestation_template).distinct
    progress = ProgressReport.new(procedures.count)

    procedures.find_each do |procedure|
      draft_revision = procedure.draft_revision
      other_revisions = procedure.revisions - [draft_revision]

      draft_attestation_template = draft_revision.attestation_template
      if draft_attestation_template.present?
        other_attestation_templates = other_revisions.map(&:attestation_template).compact - [draft_attestation_template]

        AttestationTemplate.transaction do
          if other_attestation_templates.present?
            AttestationTemplate.where(id: other_attestation_templates.map(&:id)).update_all(procedure_id: nil)
          end
          AttestationTemplate.where(procedure_id: procedure.id).update_all(procedure_id: nil)
          ProcedureRevision
            .where(attestation_template_id: draft_attestation_template.id)
            .update_all(attestation_template_id: nil)
          draft_attestation_template.update_column(:procedure_id, procedure.id)
        end
      end

      progress.inc
    end
    progress.finish

    # Update task as completed.  If you remove the line below, the task will
    # run with every deploy (or every time you call after_party:run).
    AfterParty::TaskRecord
      .create version: AfterParty::TaskRecorder.new(__FILE__).timestamp
  end
end
