# frozen_string_literal: true

module AddressableColumnConcern
  extend ActiveSupport::Concern

  included do
    def columns(displayable: true, prefix: nil)
      super.concat([
        ["code postal (5 chiffres)", '$.postal_code', []],
        ["commune", '$.city_name', []],
        ["département", '$.departement_code', APIGeoService.departements.map { ["#{_1[:code]} – #{_1[:name]}", _1[:code]] }],
        ["region", '$.region_name', APIGeoService.regions.map { [_1[:name], _1[:name]] }]
      ].map do |(label, jsonpath, options_for_select)|
        Columns::JSONPathColumn.new(
          stable_id:,
          options_for_select:,
          jsonpath:,
          label: "#{libelle_with_prefix(prefix)} – #{label}"
        )
      end)
    end
  end
end
