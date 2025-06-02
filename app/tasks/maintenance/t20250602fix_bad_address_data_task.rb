# frozen_string_literal: true

module Maintenance
  class T20250602fixBadAddressDataTask < MaintenanceTasks::Task
    # Documentation: cette tâche modifie les données pour…

    include RunnableOnDeployConcern
    include StatementsHelpersConcern

    # Uncomment only if this task MUST run imperatively on its first deployment.
    # If possible, leave commented for manual execution later.
    # run_on_first_deploy

    def collection
      Champs::AddressChamp.all
    end

    def process(champ)
      is_partial_address = champ.department_code.blank?
      is_international_address = champ.country_code != 'FR'

      if is_partial_address && is_international_address

        champ.update_column(:value_json, champ.value_json.merge(
          department_code: '99',
          department_name: 'Etranger'
        ))
      end
    end

    def count
      with_statement_timeout("5min") do
        collection.count(:id)
      end
    end
  end
end
