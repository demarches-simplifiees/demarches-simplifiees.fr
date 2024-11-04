# frozen_string_literal: true

module AddressableColumnConcern
  extend ActiveSupport::Concern

  included do
    def columns(procedure:, displayable: true, prefix: nil)
      super.concat([
        ["code postal (5 chiffres)", '$.postal_code', :text],
        ["commune", '$.city_name', :text],
        ["département", '$.departement_code', :enum],
        ["region", '$.region_name', :enum]
      ].map do |(label, jsonpath, type)|
        Columns::JSONPathColumn.new(
          procedure_id: procedure.id,
          stable_id:,
          tdc_type: type_champ,
          label: "#{libelle_with_prefix(prefix)} – #{label}",
          jsonpath:,
          displayable:,
          type:
        )
      end)
    end
  end
end
