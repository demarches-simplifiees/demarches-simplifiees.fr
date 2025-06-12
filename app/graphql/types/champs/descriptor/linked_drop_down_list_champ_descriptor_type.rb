# frozen_string_literal: true

module Types::Champs::Descriptor
  class LinkedDropDownListChampDescriptorType < Types::BaseObject
    implements Types::ChampDescriptorType

    field :options, [String], "List des options d’un champ avec selection.", null: true

    def options
      object.type_de_champ.drop_down_options.reject(&:empty?)
    end
  end
end
