# frozen_string_literal: true

module Maintenance
  class T20250625updateProcedurePresentationFiltersWithMessageUsagerTask < MaintenanceTasks::Task
    # Documentation: cette tâche modifie les données pour…

    include RunnableOnDeployConcern
    include StatementsHelpersConcern

    # Uncomment only if this task MUST run imperatively on its first deployment.
    # If possible, leave commented for manual execution later.
    run_on_first_deploy

    STATE_FILTERS = [
      :tous_filters,
      :suivis_filters,
      :traites_filters,
      :a_suivre_filters,
      :archives_filters,
      :expirant_filters,
      :supprimes_filters,
      :supprimes_recemment_filters,
    ].freeze

    def collection
      ProcedurePresentation.includes(assign_to: :procedure)
    end

    def process(pp)
      Rails.logger.debug { "Task T20250625updateProcedurePresentationFiltersWithMessageUsagerTask process procedure_presentation_id=##{pp.id}" }
      changed_pp = false

      STATE_FILTERS.each do |state_filter|
        current_state_filters = pp.send(state_filter)
        next if current_state_filters.empty?
        next unless current_state_filters.any? { |f| f.column.table == 'dossier_notifications' }
        changed_pp = true

        new_state_filters = current_state_filters.map do |filter|
          if filter.column.table == "dossier_notifications" && filter.filter == "message_usager"
            FilteredColumn.new(
              column: pp.procedure.dossier_notifications_column,
              filter: "message"
            )
          else
            filter
          end
        end

        pp.send("#{state_filter}=", new_state_filters)
      # a column can be not found for various reasons (deleted tdc, changed type, etc)
      # in this case we just ignore the error and continue
      rescue ActiveRecord::RecordNotFound
      end

      pp.save! if changed_pp
    end
  end
end
