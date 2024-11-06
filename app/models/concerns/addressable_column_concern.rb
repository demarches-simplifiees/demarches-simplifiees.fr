# frozen_string_literal: true

module AddressableColumnConcern
  extend ActiveSupport::Concern

  included do
    def columns(procedure:, displayable: true, prefix: nil)
      departement_options = APIGeoService.departements
        .map { ["#{_1[:code]} – #{_1[:name]}", _1[:code]] }
      region_options = APIGeoService.regions.map { [_1[:name], _1[:name]] }

      addressable_columns = [
        ["code postal (5 chiffres)", '$.postal_code', :text, []],
        ["commune", '$.city_name', :text, []],
        ["département", '$.departement_code', :enum, departement_options],
        ["region", '$.region_name', :enum, region_options]
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

      super.concat(addressable_columns)
    end
  end
end
