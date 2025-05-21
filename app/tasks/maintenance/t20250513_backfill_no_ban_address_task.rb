# frozen_string_literal: true

module Maintenance
  class T20250513BackfillNoBanAddressTask < MaintenanceTasks::Task
    # Documentation: marque les anciennes adresses qui n'avaient pas
    # été validées comme étant étant hors BAN
    # Cf https://github.com/demarches-simplifiees/demarches-simplifiees.fr/pull/10037

    include RunnableOnDeployConcern
    include StatementsHelpersConcern

    def collection
      with_statement_timeout("15min") do
        Champs::AddressChamp.all
      end
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
