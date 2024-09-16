# frozen_string_literal: true

module AddressableColumnConcern
  extend ActiveSupport::Concern

  included do
    def columns(displayable: true, prefix: nil)
      super.concat([
        ["code postal (5 chiffres)", ['postal_code'], :text],
        ["commune", ['city_name'], :text],
        ["département", ['departement_code'], :enum],
        ["region", ['region_name'], :enum]
      ].map do |(label, value_column, type)|
        Columns::JSONPathColumn.new(
          table: Column::TYPE_DE_CHAMP_TABLE,
          column: stable_id,
          label: "#{libelle_with_prefix(prefix)} – #{label}",
          displayable: false,
          type:,
          value_column:
        )
      end)
    end
  end
end
