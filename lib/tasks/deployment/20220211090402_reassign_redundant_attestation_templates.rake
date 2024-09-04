# frozen_string_literal: true

namespace :after_party do
  desc 'Deployment task: reassign_redundant_attestation_templates'
  task reassign_redundant_attestation_templates: :environment do
    rake_puts "Running deploy task 'reassign_redundant_attestation_templates'"

    procedures = Procedure.publiees_ou_closes.joins(:draft_attestation_template, :published_attestation_template)
    progress = ProgressReport.new(procedures.count)

    # On all published procedures with disabled revisions draft_attestation_template should be the same as published_attestation_template
    # Let's not destroy redundant attestation_templates for now. We can clean orphans later.
    procedures.find_each do |procedure|
      progress.inc
      if !procedure.feature_enabled?(:procedure_revisions)
        draft_attestation_template = procedure.draft_attestation_template
        published_attestation_template = procedure.published_attestation_template
        if draft_attestation_template && published_attestation_template && draft_attestation_template != published_attestation_template
          procedure.published_revision.update(attestation_template_id: draft_attestation_template.id)
        end
      end
    end
    progress.finish

    # Update task as completed.  If you remove the line below, the task will
    # run with every deploy (or every time you call after_party:run).
    AfterParty::TaskRecord
      .create version: AfterParty::TaskRecorder.new(__FILE__).timestamp
  end
end
