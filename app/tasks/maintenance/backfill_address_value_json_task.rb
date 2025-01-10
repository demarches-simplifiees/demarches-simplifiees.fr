# frozen_string_literal: true

module Maintenance
  class BackfillAddressValueJSONTask < MaintenanceTasks::Task
    # task run on 15/01/2025, needed for address columns
    include RunnableOnDeployConcern
    include StatementsHelpersConcern

    no_collection

    def process
      sql = "UPDATE champs SET value_json = data WHERE type = 'Champs::AddressChamp' AND data IS NOT NULL;"

      with_statement_timeout("15min") do
        Champ.connection.execute(sql)
      end
    end
  end
end
