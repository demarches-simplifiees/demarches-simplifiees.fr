# frozen_string_literal: true

module Maintenance
  class T20251105BackfillProConnectRestrictionTask < MaintenanceTasks::Task
    # Backfill pro_connect_restriction (nouvelle colonne enum) à partir de pro_connect_restricted (ancienne colonne boolean)
    # Convertit les procédures avec pro_connect_restricted=true en pro_connect_restriction=:instructeurs

    include RunnableOnDeployConcern
    include StatementsHelpersConcern

    run_on_first_deploy

    def collection
      Procedure.where(pro_connect_restriction: :none).where(pro_connect_restricted: true)
    end

    def process(procedure)
      procedure.update_column(:pro_connect_restriction, Procedure.pro_connect_restrictions[:instructeurs])
    end
  end
end
