# frozen_string_literal: true

module Types::Champs
  class RegionChampType < Types::BaseObject
    implements Types::ChampType

    class RegionType < Types::BaseObject
      field :name, String, null: false
      field :code, String, null: false
    end

    field :region, RegionType, null: true

    def region
      object if object.external_id.present?
    end
  end
end
