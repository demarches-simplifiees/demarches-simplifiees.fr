module AddressableColumnConcern
  extend ActiveSupport::Concern

  included do
    def facets(table:)
      super.concat([
        Columns::JSONPathColumn.new(
          table:,
          virtual: true,
          column: stable_id,
          label: "#{libelle} – code postal (5 chiffres)",
          type: :text,
          value_column: ['value_json', 'postal_code']
        ),
        Columns::JSONPathColumn.new(
          table:,
          virtual: true,
          column: stable_id,
          label: "#{libelle} – commune",
          type: :text,
          value_column: ['value_json', 'city_name']
        ),
        Columns::JSONPathColumn.new(
          table:,
          virtual: true,
          column: stable_id,
          label: "#{libelle} – département",
          type: :enum,
          value_column: ['value_json', 'departement_code']
        ),
        Columns::JSONPathColumn.new(
          table:,
          virtual: true,
          column: stable_id,
          label: "#{libelle} – region",
          type: :enum,
          value_column: ['value_json', 'region_name']
        )
      ])
    end
  end
end
