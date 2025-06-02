# frozen_string_literal: true

module Types::Champs::Descriptor
  class RegionChampDescriptorType < Types::BaseObject
    implements Types::ChampDescriptorType

    field :options, [Types::Champs::RegionChampType::RegionType], "List des regions.", null: true

    def options
      APIGeoService.regions
    end
  end
end
