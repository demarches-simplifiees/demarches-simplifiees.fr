# frozen_string_literal: true

module AddressableColumnConcern
  extend ActiveSupport::Concern

  included do
    def addressable_columns(procedure:, displayable: true, prefix: nil)
      [
        ["code postal (5 chiffres)", '$.postal_code', :text, []],
        ["commune", '$.city_name', :text, []],
        ["département", '$.departement_code', :enum, APIGeoService.departement_options],
        ["region", '$.region_name', :enum, APIGeoService.region_options]
      ].map do |(label, jsonpath, type, options_for_select)|
        Columns::JSONPathColumn.new(
          procedure_id: procedure.id,
          stable_id:,
          tdc_type: type_champ,
          label: "#{libelle_with_prefix(prefix)} – #{label}",
          jsonpath:,
          displayable:,
          options_for_select:,
          type:
        )
      end
    end
  end
end
