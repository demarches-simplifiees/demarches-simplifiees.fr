# frozen_string_literal: true

module Types::Champs::Descriptor
  class DepartementChampDescriptorType < Types::BaseObject
    implements Types::ChampDescriptorType

    field :options, [Types::Champs::DepartementChampType::DepartementType], "List des departements.", null: true

    def options
      APIGeoService.departements
    end
  end
end
