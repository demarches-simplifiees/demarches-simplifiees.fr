# frozen_string_literal: true

module Maintenance
  class T20250908backfillAttestationTemplatesTypeTask < MaintenanceTasks::Task
    include RunnableOnDeployConcern
    include StatementsHelpersConcern

    # Uncomment only if this task MUST run imperatively on its first deployment.
    # If possible, leave commented for manual execution later.
    # run_on_first_deploy

    def collection
      AttestationTemplate.where(type: nil)
    end

    def process(attestation_template)
      attestation_template.update!(type: :acceptation)
    end
  end
end
