# frozen_string_literal: true

module Maintenance
  class T20250602fixBadAddressDataTask < MaintenanceTasks::Task
    # Documentation: rattrape des champs adresses avec des données incohérentes ou incomplètes
    # après le déploiement du nouveau champ adresse hors BAN.

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

      if champ.department_code == "99" && !is_international_address && champ.city_code.present? && champ.postal_code.present?
        city_data = APIGeoService.parse_city_code_and_postal_code("#{champ.city_code}-#{champ.postal_code}")

        return if city_data.blank?

        champ.update_column(:value_json, champ.value_json.merge!(city_data))
      end
    end

    def count
      with_statement_timeout("5min") do
        collection.count(:id)
      end
    end
  end
end
