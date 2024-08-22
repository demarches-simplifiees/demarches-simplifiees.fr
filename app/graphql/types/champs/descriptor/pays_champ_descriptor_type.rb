# frozen_string_literal: true

module Types::Champs::Descriptor
  class PaysChampDescriptorType < Types::BaseObject
    implements Types::ChampDescriptorType

    field :options, [Types::Champs::PaysChampType::PaysType], "List des pays.", null: true

    def options
      APIGeoService.countries
    end
  end
end
