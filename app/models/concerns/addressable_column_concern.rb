# frozen_string_literal: true

module AddressableColumnConcern
  extend ActiveSupport::Concern

  included do
    def columns(table:)
      super.concat([
        Columns::JSONPathColumn.new(
          table:,
          displayable: false,
          column: stable_id,
          label: "#{libelle} – code postal (5 chiffres)",
          type: :text,
          value_column: ['postal_code']
        ),
        Columns::JSONPathColumn.new(
          table:,
          displayable: false,
          column: stable_id,
          label: "#{libelle} – commune",
          type: :text,
          value_column: ['city_name']
        ),
        Columns::JSONPathColumn.new(
          table:,
          displayable: false,
          column: stable_id,
          label: "#{libelle} – département",
          type: :enum,
          value_column: ['departement_code']
        ),
        Columns::JSONPathColumn.new(
          table:,
          displayable: false,
          column: stable_id,
          label: "#{libelle} – région",
          type: :enum,
          value_column: ['region_name']
        )
      ])
    end
  end
end
