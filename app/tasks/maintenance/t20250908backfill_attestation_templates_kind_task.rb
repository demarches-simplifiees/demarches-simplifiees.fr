# frozen_string_literal: true

module Maintenance
  class T20250908backfillAttestationTemplatesKindTask < MaintenanceTasks::Task
    include RunnableOnDeployConcern
    include StatementsHelpersConcern

    # Uncomment only if this task MUST run imperatively on its first deployment.
    # If possible, leave commented for manual execution later.
    # run_on_first_deploy

    def collection
      AttestationTemplate.where(kind: nil).in_batches
    end

    def process(batch_of_attestation_templates)
      batch_of_attestation_templates.update_all(kind: :acceptation)
    end
  end
end
