# frozen_string_literal: true

module Types::Champs
  class CarteChampType < Types::BaseObject
    implements Types::ChampType

    field :geo_areas, [Types::GeoAreaType], null: false

    def geo_areas
      dataloader.with(Sources::Association, :geo_areas).load(object)
    end
  end
end
