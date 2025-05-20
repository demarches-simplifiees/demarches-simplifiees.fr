# frozen_string_literal: true

module Maintenance
  class T20250513BackfillNoBanAddressTask < MaintenanceTasks::Task
    # Documentation: cette tâche modifie les données pour…

    include RunnableOnDeployConcern
    include StatementsHelpersConcern

    def collection
      Champs::AddressChamp.all
    end

    def process(champ)
      if champ.legacy_not_ban?
        value_json = {
          not_in_ban: 'true',
          street_address: champ.value,
          label: champ.value
        }
        champ.update_column(:value_json, value_json)
      end
    end
  end
end
