# frozen_string_literal: true

module Maintenance
  class T20250219MigratePathRewriteToProcedurePathsTask < MaintenanceTasks::Task
    # Documentation: cette tâche modifie les données pour ne plus utiliser les PathRewrite mais les ProcedurePaths

    include RunnableOnDeployConcern
    include StatementsHelpersConcern

    # Uncomment only if this task MUST run imperatively on its first deployment.
    # If possible, leave commented for manual execution later.
    run_on_first_deploy

    def collection
      PathRewrite.all
    end

    def process(element)
      destination_procedure = Procedure.find_with_path(element.to).first

      if destination_procedure.nil?
        Rails.logger.info("Destination procedure not found for #{element.to} (#{element.id}), skipping")
        return
      end

      origin_procedure = Procedure.find_with_path(element.from).first

      if origin_procedure == destination_procedure
        Rails.logger.info("Destination procedure is the same as the source procedure (#{element.id}), skipping")
        return
      end

      previous_canonical_path = destination_procedure.canonical_path

      destination_procedure.procedure_paths << ProcedurePath.find_or_initialize_by(path: element.from)

      # reset the canonical path
      destination_procedure.claim_path!(destination_procedure.administrateurs.first, previous_canonical_path)
    end
  end
end
